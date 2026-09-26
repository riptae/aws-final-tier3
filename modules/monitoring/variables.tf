variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "notification_email" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

