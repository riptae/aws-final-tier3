variable "name_prefix" {
    description = "Project name prefix"
    type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type = string
}

variable "azs" {
  description = "Availaility zones"
  type = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type = list(string)
}

variable "private_web_subnet_cidrs" {
  description = "Private web subnet CIDRs"
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs"
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs"
  type = list(string)
}

variable "common_tags" {
  description = "Common resource tags"
  type = map(string)
}