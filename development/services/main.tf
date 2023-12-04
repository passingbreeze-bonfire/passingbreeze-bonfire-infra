data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "passingbreeze"
    workspaces = {
      name = "passingbreeze-bonfire-dev-network"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

locals {
  cluster_name = var.dev_eks_cluster_name
  tags         = var.dev_tags
}

#######
# EKS #
#######

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.28"

  vpc_id     = data.terraform_remote_state.network.outputs.dev_vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.dev_vpc_private_subnets

  cluster_endpoint_public_access         = true
  cluster_endpoint_private_access        = true
  manage_aws_auth_configmap              = true
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons_timeouts = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  cluster_addons = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.6"
    }
    kube-proxy = {
      addon_version = "v1.28.2-eksbuild.2"
    }
    vpc-cni = {
      addon_version            = "v1.15.4-eksbuild.1"
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_https_with_self = {
      description                = "EKS Cluster allows 443 port to get API call"
      type                       = "ingress"
      from_port                  = 443
      to_port                    = 443
      protocol                   = "TCP"
      source_node_security_group = true
    },
    ingress_http_with_self = {
      description                = "EKS Cluster allows 80 port to get API call"
      type                       = "ingress"
      from_port                  = 80
      to_port                    = 80
      protocol                   = "TCP"
      source_node_security_group = true
    },
    ingress_443_api = {
      description = "API ingress for 443"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr_block]
    },
    ingress_80_api = {
      description = "API ingress for 80"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr_block]
    },
    egress = {
      description = "outbound"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ## Fargate
  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
  }

  ## Node Security Group
  node_security_group_tags = {
    "karpenter.sh/discovery" = format("%s-eks", local.cluster_name) # for Karpenter
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    egress = {
      description = "outbound"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  aws_auth_roles = [
    { ## for Karpenter
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = ">= 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}
