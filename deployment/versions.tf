terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34"
    }
  }

  required_version = ">= 0.15"
}
