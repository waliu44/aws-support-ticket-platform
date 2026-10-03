terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Project     = "aws-support-ticket-platform"
      Environment = "learning"
      ManagedBy   = "Terraform"
    }
  }
}