terraform {
  cloud {
    organization = "passingbreeze"

    workspaces {
      name = "passingbreeze-bonfire-dev-security-groups"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  name       = "passingbreeze-bonfire"
  env        = "dev"
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.dev_tags
}


# aws_service_endpoint_sg

