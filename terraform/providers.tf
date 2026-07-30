terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "spooky-tfstate-590575330542"
    key            = "project1-webapp/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "spooky-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "shopfront-webapp"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
