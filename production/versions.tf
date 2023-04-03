terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }

  backend "remote" {
    organization = "passingbreeze"

    workspaces {
      name = "Darrae_Production"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
