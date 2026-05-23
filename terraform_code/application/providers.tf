provider "aws" {
  region = var.aws_region
}

terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8.0"
    }
  }

  backend "s3" {
    bucket       = "tf-state-yt-analyzer-kdklooiuwoe2220"
    key          = "remote-backend/terraform.tfstate"
    region       = "ap-southeast-3"
    encrypt      = "true"
    use_lockfile = true

  }
}



