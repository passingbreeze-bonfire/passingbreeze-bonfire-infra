variable "name" {
  type = string
}

variable "dev_vpc_cidr" {
  type = string
}

variable "region" {
  type = string
}

variable "aws_private_cidrs" {
  type = list(string)
}

variable "aws_public_cidrs" {
  type = list(string)
}
