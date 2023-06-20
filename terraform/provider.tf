terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.7"
    }
  }

  required_version = ">=1.0.0"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
  default_tags {
    tags = {
      managed_by = local.service_id
    }
  }
}
