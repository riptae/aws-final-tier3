########################################
# 1. Network
########################################

module "network" {
  source = "../modules/network"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  public_subnet_cidrs      = var.public_subnet_cidrs
  private_web_subnet_cidrs = var.private_web_subnet_cidrs

  # APP, DB subnet X
  private_app_subnet_cidrs = []
  private_db_subnet_cidrs  = []
}

########################################
# 2. Security Groups
########################################

module "security" {
  source = "../modules/security"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id     = module.network.vpc_id
  my_ip_cidr = var.my_ip_cidr
}

########################################
# 3. Compute: Web 2대 + Bastion 1대
########################################

module "compute" {
  source = "../modules/compute"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  ami_id        = var.ami_id
  instance_type = var.instance_type

  public_subnet_id      = module.network.public_subnet_ids[0]
  private_web_subnet_ids = module.network.private_web_subnet_ids

  # 현재 모듈의 변수 이름이 parivate로 정의되어 있으므로 그대로 사용
  # 빈 목록을 전달하면 App EC2 count가 0이 됨
  parivate_app_subnet_ids = []

  bastion_sg_id = module.security.bastion_sg_id
  web_sg_id     = module.security.web_sg_id
  app_sg_id     = module.security.app_sg_id

  # NAT 및 라우팅 구성이 끝난 뒤 EC2 초기화 시작
  # user_data의 dnf / nginx 설치에 인터넷 연결 필요
  depends_on = [module.network]
}

########################################
# 4. Application Load Balancer
########################################

module "alb" {
  source = "../modules/alb"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  alb_sg_id        = module.security.alb_sg_id
  web_instance_ids = module.compute.web_instance_ids
}

########################################
# 5. Route 53 Hosted Zone
########################################

module "hosted_zone" {
  source = "../modules/hosted_zone"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  domain_name = var.domain_name
}

########################################
# 6. CloudFront용 ACM: us-east-1
########################################

module "acm" {
  source = "../modules/acm"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  domain_name               = var.domain_name
  subject_alternative_names = []

  providers = {
    aws = aws.us_east_1
  }
}

########################################
# 7. ACM DNS 검증 레코드
########################################

module "dns_validation" {
  source = "../modules/dns_validation"

  domain_validation_options = module.acm.domain_validation_options
  route53_zone_id           = module.hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider = aws.us_east_1

  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = module.dns_validation.validation_record_fqdns
}

########################################
# 8. CloudFront
########################################

module "cdn" {
  source = "../modules/cdn"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  alb_dns_name = module.alb.alb_dns_name

  aliases = [var.record_name]

  aws_acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn
}

########################################
# 9. Route 53 Alias → CloudFront
########################################

module "dns_alias" {
  source = "../modules/dns_alias"

  route53_zone_id = module.hosted_zone.zone_id
  record_name     = var.record_name

  cloudfront_domain_name    = module.cdn.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id
}