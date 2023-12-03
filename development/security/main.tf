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

data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "passingbreeze"
    workspaces = {
      name = "passingbreeze-bonfire-dev-network"
    }
  }
}

#######
# IAM #
#######

##################
# Security Group #
##################
module "security_group" {
  source   = "./security_groups"
  vpc_id   = data.terraform_remote_state.network.outputs.dev_vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr_block
  tags     = var.dev_tags
}
