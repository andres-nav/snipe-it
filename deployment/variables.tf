variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "git_repo" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "root_block_device" {
  type = object({
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
  })

  default = {
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 1
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "backup_bucket_prefix" {
  type        = string
  default     = "snipeit-backup-"
  description = "The ARN of the s3 backup bucket"
}
