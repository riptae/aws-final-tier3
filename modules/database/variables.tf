variable "name_prefix" { type = string }
variable "common_tags" { type = map(string) }

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}

variable "db_name" {
    type = string
    default = "appdb"
}

variable "db_username" {
    type = string
    default = "admin"
}

variable "db_password" {
  type = string
  sensitive = true
}