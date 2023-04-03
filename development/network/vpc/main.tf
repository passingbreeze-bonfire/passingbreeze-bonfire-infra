module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 3.0"

  name = var.name
  cidr = var.dev_vpc_cidr

  azs             = ["${var.region}a", "${var.region}c", "${var.region}d"]
  private_subnets = var.aws_private_cidrs
  public_subnets  = var.aws_public_cidrs

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false

  # VPC Flow Logs (Cloudwatch log group and roles role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = {
    "Automation" = "Terraform"
  }
}
