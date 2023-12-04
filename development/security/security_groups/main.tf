
data "terraform_remote_state" "services" {
  backend = "remote"

  config = {
    organization = "passingbreeze"
    workspaces = {
      name = "passingbreeze-bonfire-dev-services"
    }
  }
}

locals {
  eks_cluster_name = var.dev_eks_cluster_name
}

# aws_service_endpoint_sg

module "aws_service_endpoint_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "service-endpoint-sg"
  description = "Security group for service endpoint"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      description = "Allow all inbound traffic from VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_rules = ["all-all"]
  tags = merge(var.tags, {
    "karpenter.sh/discovery" = local.eks_cluster_name
  })
}

resource "aws_security_group_rule" "cluster_sg_rule" {
  from_port                = 0
  protocol                 = "-1"
  source_security_group_id = data.terraform_remote_state.services.outputs.cluster_security_group_id
  security_group_id        = module.aws_service_endpoint_sg.security_group_id
  to_port                  = 0
  type                     = "ingress"
}
