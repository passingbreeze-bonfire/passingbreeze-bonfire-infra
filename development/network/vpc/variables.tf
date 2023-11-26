variable "dev_vpc_name" {
  type = string
}

variable "dev_region" {
  type = string
}

variable "dev_tags" {
  type = map(string)
  default = {
    "Org"         = "Passingbreeze-bonfire",
    "Environment" = "Development",
    "Automation"  = "Terraform_Cloud"
  }
}
