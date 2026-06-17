locals {
  validation_records = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
        name = dvo.resource_record_name
        type = dvo.resource_record_type
        record = dvo.resource_record_value
    }
  }
}