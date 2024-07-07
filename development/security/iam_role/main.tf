terraform {
  cloud {
    organization = "passingbreeze"

    workspaces {
      name = "passingbreeze-bonfire-infra-dev-security-iam-role"
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

data "aws_caller_identity" "current" {}

locals {
  name       = "passingbreeze-bonfire"
  env        = "dev"
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.dev_tags
}

# resource "aws_iam_role" "external_dns" {
#   name = format("%s-%s-cluster-external-dns-role", local.name, local.env)
#
#   assume_role_policy = <<EOF
# {
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Federated": "arn:aws:iam::${local.account_id}:oidc-provider/*"
#      },
#      "Action": "sts:AssumeRoleWithWebIdentity",
#      "Condition": {
#        "StringEquals": {
#          "*:sub": "system:serviceaccount:kube-system:external-dns"
#        }
#      }
#    }
#  ]
# }
# EOF
# }
