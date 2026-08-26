output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}

output "domain_validation_options" { // 검증용 DNS정보
  value = aws_acm_certificate.this.domain_validation_options
}