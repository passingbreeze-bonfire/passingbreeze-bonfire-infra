module "dev_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0.0"

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_ipv6          = true

  name      = var.dev_vpc_name
  ipv6_cidr = var.dev_vpc_cidr

  azs                                             = tolist([for az in ["a", "c"] : "${var.dev_region}${az}"])
  public_subnet_ipv6_native                       = true
  public_subnet_ipv6_prefixes                     = [56, 56]
  private_subnet_ipv6_native                      = true
  private_subnet_ipv6_prefixes                    = [56, 56]
  database_subnet_assign_ipv6_address_on_creation = true
  database_subnet_ipv6_prefixes                   = [56, 56]
  create_database_subnet_group                    = true
  create_database_subnet_route_table              = true
  create_database_internet_gateway_route          = false

  # VPC Flow Logs (Cloudwatch log group and roles role will be created)
  #  enable_flow_log                      = false
  create_egress_only_igw = true
  enable_nat_gateway     = false

  tags = var.dev_tags
}
