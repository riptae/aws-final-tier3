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

variable "web_unhealthy_alarm_arn" {
  description = "Web 비정상 대상 알람 ARN"
  type        = string
}
