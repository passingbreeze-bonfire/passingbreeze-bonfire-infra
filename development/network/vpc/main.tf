module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = true

  name                         = var.dev_vpc_name
  azs                          = tolist([for az in ["a", "c"] : "${var.dev_region}${az}"])
  public_subnet_ipv6_native    = true
  public_subnet_ipv6_prefixes  = [56, 56]
  private_subnet_ipv6_native   = true
  private_subnet_ipv6_prefixes = [56, 56]

  create_egress_only_igw = true
  enable_nat_gateway     = false
  tags                   = var.dev_tags
}
