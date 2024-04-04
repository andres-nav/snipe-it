variable "instance_type" {
  type = string
}

variable "root_block_device" {
  type = object({
    volume_size           = number
    volume_type           = string
    delete_on_termination = bool
  })
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}

variable "backup_bucket_arn" {
  type        = string
  description = "The ARN of the s3 backup bucket"
}
