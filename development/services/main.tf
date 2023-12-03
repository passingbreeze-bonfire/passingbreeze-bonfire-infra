data "terraform_remote_state" "dev_network" {
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
  name     = var.dev_eks_cluster_name
  vpc_name = data.terraform_remote_state.dev_network.outputs.dev_vpc_name
  tags = merge(var.dev_tags, {
    "Name" = local.vpc_name
  })
}

#######
# EKS #
#######

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.name
  cluster_version = "1.28"

  vpc_id     = data.terraform_remote_state.dev_network.outputs.dev_vpc_id
  subnet_ids = data.terraform_remote_state.dev_network.outputs.dev_vpc_private_subnets

  cluster_endpoint_public_access         = true
  manage_aws_auth_configmap              = true
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons = {
    coredns = {
      addon_version = "v1.10.1-eksbuild.6"
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure that we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu = "1"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "8G"
          }
          requests = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
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
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  ## Fargate
  fargate_profiles = {
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
  }

  ## Node Security Group
  node_security_group_tags = {
    "karpenter.sh/discovery" = format("%s-eks", local.vpc_name) # for Karpenter
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
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
