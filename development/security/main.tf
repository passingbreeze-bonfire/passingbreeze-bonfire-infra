terraform {
  cloud {
    organization = "passingbreeze"

    workspaces {
      name = "passingbreeze-bonfire-dev-security"
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
