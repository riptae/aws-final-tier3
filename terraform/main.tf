# 0. Public Hosted Zone: 생성된 NS를 Cafe24에 등록한 뒤 인증서/CDN 연결
module "hosted_zone" {
  source = "../modules/hosted_zone"

  domain_name = var.domain_name
  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

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

  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
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
# 3. Compute: Bastion + Web + App
########################################

module "compute" {
  source = "../modules/compute"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  ami_id        = var.ami_id
  instance_type = var.instance_type

  public_subnet_id       = module.network.public_subnet_ids[0]
  private_web_subnet_ids = module.network.private_web_subnet_ids

  # 현재 모듈의 변수 이름이 parivate로 정의되어 있으므로 그대로 사용
  parivate_app_subnet_ids = module.network.private_app_subnet_ids

  bastion_sg_id = module.security.bastion_sg_id
  web_sg_id     = module.security.web_sg_id
  app_sg_id     = module.security.app_sg_id

  # NAT 및 라우팅 구성이 끝난 뒤 EC2 초기화 시작
  # user_data의 dnf / nginx 설치에 인터넷 연결 필요
  depends_on = [module.network]
}

########################################
# 4. Database: Private RDS MySQL
########################################
module "database" {
  source = "../modules/database"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  private_db_subnet_ids = module.network.private_db_subnet_ids
  db_sg_id              = module.security.db_sg_id
  db_name               = "appdb"
  db_username           = "admin"
  db_password           = var.db_password
}

# 5. Public ALB → Private Web A / B
module "alb" {
  source = "../modules/alb"

  name_prefix       = local.name_prefix
  common_tags       = local.common_tags
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  web_instance_ids  = module.compute.web_instance_ids

  depends_on = [module.network]
}

# 6. Nginx 장애 감지 → SNS 이메일 알림
module "monitoring" {
  source = "../modules/monitoring"

  name_prefix             = local.name_prefix
  common_tags             = local.common_tags
  notification_email      = var.notification_email
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}

# 7. 정상 / 비정상 Web 수와 알람 상태 시각화
module "dashboard" {
  source = "../modules/dashboard"

  name_prefix             = local.name_prefix
  aws_region              = var.aws_region
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  web_unhealthy_alarm_arn = module.monitoring.web_unhealthy_alarm_arn
}

# 8. CloudFront용 ACM 인증서: us-east-1에서 요청
module "acm" {
  source = "../modules/acm"

  providers = {
    aws = aws.us_east_1
  }

  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
  domain_name               = var.domain_name
  subject_alternative_names = var.record_name == var.domain_name ? [] : [var.record_name]
}

# 9. Hosted Zone에 ACM DNS 검증 CNAME 생성
module "dns_validation" {
  source = "../modules/dns_validation"

  route53_zone_id           = module.hosted_zone.zone_id
  domain_validation_options = module.acm.domain_validation_options
}

# Cafe24의 NS 위임이 반영되어 공개 DNS에서 CNAME이 조회되어야 완료됨.
# CloudFront에는 발급 완료를 확인한 인증서 ARN을 전달한다.
resource "aws_acm_certificate_validation" "this" {
  provider = aws.us_east_1

  certificate_arn         = module.acm.certificate_arn
  validation_record_fqdns = module.dns_validation.validation_record_fqdns
}

# 10. HTTPS CloudFront → HTTP ALB → Web → App
module "cdn" {
  source = "../modules/cdn"

  name_prefix             = local.name_prefix
  common_tags             = local.common_tags
  alb_dns_name            = module.alb.alb_dns_name
  aliases                 = [var.record_name]
  aws_acm_certificate_arn = aws_acm_certificate_validation.this.certificate_arn
}

# 11. 서비스 도메인 A Alias → CloudFront
module "dns_alias" {
  source = "../modules/dns_alias"

  route53_zone_id           = module.hosted_zone.zone_id
  record_name               = var.record_name
  cloudfront_domain_name    = module.cdn.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cdn.cloudfront_hosted_zone_id
}
