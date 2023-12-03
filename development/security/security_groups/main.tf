
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
  tags         = var.tags
}
