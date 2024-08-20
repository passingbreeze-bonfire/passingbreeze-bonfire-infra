output "dev_vpc_id" {
  value = module.dev_vpc.vpc_id
}

output "dev_vpc_name" {
  value = module.dev_vpc.name
}

output "vpc_cidr_block" {
  value = module.dev_vpc.vpc_cidr_block
}

output "dev_vpc_public_subnets" {
  value = module.dev_vpc.public_subnets
}

output "dev_vpc_private_subnets" {
  value = module.dev_vpc.private_subnets
}

output "dev_vpc_database_subnets" {
  value = module.dev_vpc.database_subnets
}

output "dev_vpc_database_subnet_group_name" {
  value = module.dev_vpc.database_subnet_group_name
}

output "dev_vpc_elasticache_subnet_group_name" {
  value = module.dev_vpc.elasticache_subnet_group_name
}
