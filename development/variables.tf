variable "dev_vpc_name" {
  type = string
}

variable "dev_aws_vpc_cidr" {
  type = string
}

variable "dev_region" {
  type = string
}

variable "dev_private_cidrs" {
  type = list(string)
}

variable "dev_public_cidrs" {
  type = list(string)
}
