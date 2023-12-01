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
  name = "passingbreeze-bonfire-dev-network"
}

module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = true
  enable_flow_log      = false
  enable_nat_gateway   = false

  name                         = var.dev_vpc_name
  azs                          = tolist([for az in ["a", "c"] : "${data.aws_region.current.name}${az}"])
  public_subnet_ipv6_native    = true
  public_subnet_ipv6_prefixes  = [0, 1]
  private_subnet_ipv6_native   = true
  private_subnet_ipv6_prefixes = [2, 3]

  create_egress_only_igw = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # for AWS Load Balancer Controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1                            # for AWS Load Balancer Controller
    "karpenter.sh/discovery"          = format("%s-eks", local.name) # for Karpenter
  }

  tags = var.dev_tags
}
