variable "name_prefix" {
    type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "web_instance_ids" {
  type = list(string)
}

variable "app_instance_ids" {
  type = list(string)
}

variable "db_instance_id" {
  type = string
}


