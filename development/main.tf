terraform {
  cloud {
    organization = "passingbreeze"

    workspaces {
      name = "passingbreeze-bonfire_Dev"
    }
  }
}

provider "aws" {
  region = var.dev_region
}

module "aws_vpc_dev" {
  source           = "./network/vpc"
  dev_vpc_name     = var.dev_vpc_name
  dev_region       = var.dev_region
  dev_aws_vpc_cidr = var.dev_aws_vpc_cidr
  dev_tags         = var.dev_tags
}
