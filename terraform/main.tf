module "network" {
  source = "../modules/network"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr

  azs = var.azs

  public_subnet_cidrs      = var.public_subnet_cidrs
  private_web_subnet_cidrs = var.private_web_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  common_tags = local.common_tags
}

module "security" {
  source = "../modules/security"

  vpc_id      = module.network.vpc_id
  name_prefix = local.name_prefix
  common_tags = local.common_tags
  my_ip_cidr  = var.my_ip_cidr

}

module "compute" {
  source = "../modules/compute"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  ami_id           = var.ami_id
  instance_type    = var.instance_type
  public_subnet_id = module.network.public_subnet_ids[0]

  private_web_subnet_ids = module.network.private_web_subnet_ids

  parivate_app_subnet_ids = module.network.private_app_subnet_ids

  bastion_sg_id = module.security.bastion_sg_id
  web_sg_id     = module.security.web_sg_id
  app_sg_id     = module.security.app_sg_id

}

module "alb" {
  source = "../modules/alb"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  alb_sg_id        = module.security.alb_sg_id
  web_instance_ids = module.compute.web_instance_ids

}

module "dns_alias" {
  source = "../modules/dns_alias"

  route53_zone_id = module.hosted_zone.zone_id
  record_name     = var.record_name

  cloudfront_domain_name    = module.cdn.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id
}

module "acm" {
  source = "../modules/acm"

  common_tags = local.common_tags
  name_prefix = local.name_prefix

  domain_name               = var.domain_name
  subject_alternative_names = []

  providers = {
    aws = aws.us_east_1
  }
}

// DNS 검증용 CNAME 레코드를 Route53 Hosted Zone에 생성
module "dns_validation" {
  source = "../modules/dns_validation"

  domain_validation_options = module.acm.domain_validation_options // 검증용 DNS정보
  route53_zone_id           = module.hosted_zone.zone_id           // 생성위치

}

// cloudfront에 tls certificate (arn) 삽입
resource "aws_acm_certificate_validation" "this" {
  provider                = aws.us_east_1
  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = module.dns_validation.validation_record_fqdns
}

module "cdn" {
  source = "../modules/cdn"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  alb_dns_name = module.alb.alb_dns_name

  aliases = [
    var.record_name
  ]

  // acm이 아닌 aws_acm_certificate_validation output임
  aws_acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn

}

module "hosted_zone" {
  source = "../modules/hosted_zone"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  domain_name = var.domain_name
}