terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.43.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = var.project
      Env       = terraform.workspace
      ManagedBy = "terraform"
    }
  }

}

locals {
  env = terraform.workspace
}