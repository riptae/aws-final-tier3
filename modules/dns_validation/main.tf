resource "aws_route53_record" "validation" {
  
  for_each = local.validation_records

  zone_id = var.route53_zone_id

  name = each.value.name
  type = each.value.type
  records = [each.value.record]

  ttl = 60
  allow_overwrite = true
}