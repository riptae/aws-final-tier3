resource "aws_route53_record" "this" {
  zone_id = var.route53_zone_id
  name = var.record_name
  type = "A"

  alias {
    name = var.cloudfront_domain_name
    zone_id = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}