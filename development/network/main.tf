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
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_region" "current" {}

locals {
  name             = var.dev_vpc_name
  eks_cluster_name = var.dev_eks_cluster_name
  tags             = var.dev_tags
  env              = "dev"
  vpc_cidr         = "10.0.0.0/16"
  azs              = tolist([for az in ["a", "c"] : "${data.aws_region.current.name}${az}"])
}

module "dev_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true

  name                = local.name
  cidr                = local.vpc_cidr
  azs                 = local.azs
  private_subnets     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets      = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  database_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  private_subnet_names = ["private-dmz", "private-server"]
  public_subnet_names  = ["public-dmz", "public-server"]

  create_database_subnet_group    = true
  create_elasticache_subnet_group = true

  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  enable_flow_log                      = false
  vpc_flow_log_tags = merge(local.tags, {
    "Name" = format("%s-flow-log", local.name)
  })

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # for AWS Load Balancer Controller
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1                      # for AWS Load Balancer Controller
    "karpenter.sh/discovery"          = local.eks_cluster_name # for Karpenter
  }

  tags = merge(local.tags, {
    Name = local.name
  })
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
