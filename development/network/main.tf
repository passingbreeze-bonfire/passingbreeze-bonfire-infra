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

data "terraform_remote_state" "security" {
  backend = "remote"

  config = {
    organization = "passingbreeze"
    workspaces = {
      name = "passingbreeze-bonfire-dev-security"
    }
  }
}

locals {
  name             = var.dev_vpc_name
  eks_cluster_name = var.dev_eks_cluster_name
  tags             = var.dev_tags
  ipv4_cidr        = "10.0.0.0/16"
  azs              = tolist([for az in ["a", "c"] : "${data.aws_region.current.name}${az}"])
}

module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames    = true
  enable_dns_support      = true
  enable_flow_log         = false
  map_public_ip_on_launch = true

  name            = local.name
  cidr            = local.ipv4_cidr
  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.ipv4_cidr, 4, k + 4)]

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # for AWS Load Balancer Controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1                      # for AWS Load Balancer Controller
    "karpenter.sh/discovery"          = local.eks_cluster_name # for Karpenter
  }

  tags = local.tags
}

/*
module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.dev_vpc.vpc_id
  security_group_ids = [data.terraform_remote_state.security.outputs.aws_service_endpoint_sg_id]

  endpoints = {
    s3 = {
      service    = "s3"
      subnet_ids = module.dev_vpc.private_subnets
      tags       = merge(var.dev_tags, { Name = "s3-vpc-endpoint" })
    },
    ec2 = {
      service    = "ec2"
      subnet_ids = module.dev_vpc.private_subnets
      tags       = merge(var.dev_tags, { Name = "ec2-vpc-endpoint" })
    },
    sts = {
      service    = "sts"
      subnet_ids = module.dev_vpc.private_subnets
      tags       = merge(var.dev_tags, { Name = "sts-vpc-endpoint" })
    },
    ssm = {
      service    = "ssm"
      subnet_ids = module.dev_vpc.private_subnets
      tags       = merge(var.dev_tags, { Name = "ssm-vpc-endpoint" })
    },
    sqs = {
      service    = "sqs"
      subnet_ids = module.dev_vpc.private_subnets
      tags       = merge(var.dev_tags, { Name = "sqs-vpc-endpoint" })
    },
  }

  tags = var.dev_tags
}
*/
