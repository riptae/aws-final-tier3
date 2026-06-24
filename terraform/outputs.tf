output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.cdn.cloudfront_domain_name
}

output "route53_name_servers" {
  value = module.hosted_zone.name_servers
}