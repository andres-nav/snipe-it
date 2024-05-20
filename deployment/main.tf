provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      project     = var.project_name
      environment = var.environment
    }
  }
}

module "infrastructure" {
  source = "./infrastructure"

  backup_bucket_prefix = var.backup_bucket_prefix
}

module "snipeit" {
  source = "./snipeit"

  git_repo             = var.git_repo
  instance_type        = var.instance_type
  root_block_device    = var.root_block_device
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  backup_bucket_name = module.infrastructure.backup_bucket_name
}
