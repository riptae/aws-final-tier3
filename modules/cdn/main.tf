resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.name_prefix}-cloudfront"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]

    cache_policy_id = local.caching_disabled_policy_id
    compress = true
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cloudfornt"
  })
}