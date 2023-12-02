terraform {
  cloud {
    organization = "passingbreeze"

    workspaces {
      name = "passingbreeze-bonfire-dev-network"
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

data "aws_region" "current" {}

locals {
  name      = "passingbreeze-bonfire-dev-network"
  ipv4_cidr = "10.24.0.0/16"
  azs       = tolist([for az in ["a", "c"] : "${data.aws_region.current.name}${az}"])
}

module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_flow_log      = false

  name            = var.dev_vpc_name
  cidr            = local.ipv4_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 8, k + 4)]

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # for AWS Load Balancer Controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1                            # for AWS Load Balancer Controller
    "karpenter.sh/discovery"          = format("%s-eks", local.name) # for Karpenter
  }

  tags = var.dev_tags
}
