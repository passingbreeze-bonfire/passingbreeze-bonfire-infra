terraform {
  backend "remote" {
    organization = "passingbreeze"

    workspaces {
      name = "Darrae_Dev"
    }
  }
}

provider "aws" {
  region = local.region
}

locals {
  region            = "us-east-1"
  dev_aws_vpc_cidr  = "10.1.0.0/16"
  aws_private_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  aws_public_cidrs  = ["10.1.4.0/24", "10.1.5.0/24"]
}

module "aws_vpc_dev" {
  source            = "./network/vpc"
  name              = "aws-dev-vpc"
  region            = local.region
  dev_vpc_cidr      = local.dev_aws_vpc_cidr
  aws_private_cidrs = local.aws_private_cidrs
  aws_public_cidrs  = local.aws_public_cidrs
}
