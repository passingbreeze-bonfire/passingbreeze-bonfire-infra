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
  ipv4_cidr = "10.0.0.0/16"
  azs       = tolist([for az in ["a", "c"] : "${data.aws_region.current.name}${az}"])
}

module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames    = true
  enable_dns_support      = true
  enable_flow_log         = false
  map_public_ip_on_launch = true

  name            = var.dev_vpc_name
  cidr            = local.ipv4_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 4, k + 4)]

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
#
#module "endpoints" {
#    source  = "terraform-aws-modules/vpc/aws//modules/endpoint-services"
#    version = ">= 5.0.0"
#
#    vpc_id = module.dev_vpc.vpc_id
#
#    enable_s3_endpoint = true
#    enable_ec2_endpoint = true
#    enable_ecr_endpoint = true
#    enable_ecr_dkr_endpoint = true
#    enable_ecr_api_endpoint = true
#    enable_logs_endpoint = true
#    enable_sts_endpoint = true
#    enable_eks_endpoint = true
#    enable_eks_endpoint_private_access = true
#    enable_eks_endpoint_public_access = true
#    enable_eks_endpoint_public_access_cidrs = ["
#}
