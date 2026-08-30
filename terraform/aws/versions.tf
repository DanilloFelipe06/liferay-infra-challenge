terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Intentionally no backend block: this module is a stub (see README.md
  # in this directory) and is not meant to be applied as part of this
  # challenge. Whoever does apply it for real should add a remote backend
  # (S3 + DynamoDB lock table, or Terraform Cloud) here first.
}

provider "aws" {
  region = var.aws_region
}
