variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.nano"
}


variable "public_subnet_id" {
  type = string
}

variable "private_web_subnet_ids" {
  type = list(string)
}

variable "parivate_app_subnet_ids" {
  type = list(string)
}

variable "bastion_sg_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

