variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
  default = {}    
}

variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  type = list(string)
  default = []
}

