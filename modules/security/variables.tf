variable "vpc_id" {
    type = string
}

variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
  default = {}
}

variable "my_ip_cidr" {
  type = string
  description = "SSH allowed IP CIDR"
}