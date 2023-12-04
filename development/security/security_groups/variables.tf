variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "The VPC CIDR"
  type        = string
}

variable "tags" {
  type = map(string)
}

variable "cluster_name" {
  type = string
}
