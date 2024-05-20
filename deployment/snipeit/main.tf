resource "aws_key_pair" "snipeit" {
  key_name   = "snipeit"
  public_key = file("${path.module}/web_key.pub")
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "snipeit_role" {
  name               = "snipeit-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "snipeit_s3_policy_attachment" {
  role       = aws_iam_role.snipeit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create an instance profile for the launch template. It cannot use the role directly.
resource "aws_iam_instance_profile" "snipeit" {
  name = "snipeit-instance-profile"
  role = aws_iam_role.snipeit_role.name
}

resource "aws_launch_template" "snipeit" {
  name_prefix   = "snipeit-"
  image_id      = data.aws_ami.latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.snipeit.key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_block_device.volume_size
      volume_type           = var.root_block_device.volume_type
      delete_on_termination = var.root_block_device.delete_on_termination
    }
  }

  vpc_security_group_ids = [aws_security_group.snipeit.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.snipeit.arn
  }

  # it is not in a different file as I need to use the s3 bucket
  user_data = base64encode(<<-EOF
              #!/usr/bin/env bash
              # This script installs Snipe-IT on a Amazon Linux 2 instance

              # Check if the script is running as root
              if [ "$EUID" -ne 0 ]; then
                  echo "This script must be run as root. Attempting to elevate privileges..."
                  exec sudo "$0" "$@"
              fi

              # Your script commands go here
              echo "Running as root now."

              # Enable logging and redirect user-data ouptut to /var/log/user-data.log
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # Variables
              SNIPEIT_DIR=/opt/snipeit
              SNIPEIT_SRC_DIR=$SNIPEIT_DIR/src
              ENV_FILEPATH=$SNIPEIT_SRC_DIR/.env
              S3_BUCKET_NAME=${var.backup_bucket_name}
              ENV_FILEPATH_REMOTE=s3://$S3_BUCKET_NAME/.env

              # Update the system
              yum update -y

              # Install required dependencies
              yum install -y yum-utils

              # Install Docker
              yum install -y docker

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker

              # Install a lower version of urllib3 as the latest version is not compatible with openssl 1.0
              pip3 uninstall -y urllib3
              pip3 install 'urllib3<2.0'

              # Install Docker Compose
              pip3 install docker-compose

              # Add the current user to the docker group and change the permissions of the docker socket
              # to allow the current user to run docker commands
              usermod -aG docker "$USER"
              chmod 666 /var/run/docker.sock

              # Install Git
              yum install -y git

              # Clone the Snipe-IT repository
              git clone --depth 1 ${var.git_repo} $SNIPEIT_DIR

              # Download the .env file
              aws s3 cp $ENV_FILEPATH_REMOTE $ENV_FILEPATH
              echo "S3_BUCKET_NAME=$S3_BUCKET_NAME" | tee -a $ENV_FILEPATH

              # Cron job to backup the database. Make sure to run as sudo
              echo "0 5 * * * make -C $SNIPEIT_SRC_DIR backup" | crontab -

              # Run the project
              make -C $SNIPEIT_SRC_DIR up

              EOF
  )

}

resource "aws_autoscaling_group" "snipeit" {
  name_prefix      = aws_launch_template.snipeit.name_prefix
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  availability_zones = data.aws_availability_zones.available.names

  launch_template {
    id      = aws_launch_template.snipeit.id
    version = "$Latest"
  }
}

resource "aws_security_group" "snipeit" {
  name = "snipeit-lb-sb"
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  vpc_id = data.aws_vpc.default.id
}
