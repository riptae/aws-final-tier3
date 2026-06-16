variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_web_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  type = list(string)
}

variable "my_ip_cidr" {
  type        = string
  description = "MY IP for SSH ACCESS"
}

######################
# COMPUTE
######################
variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

######################
# DATABASE
######################
variable "db_password" {
  type      = string
  sensitive = true
}

variable "notification_email" {
  type = string
}

######################
# Route53
######################
variable "domain_name" {
  type = string
}

variable "app_subdomain" {
  type = string
  default = "app"
}