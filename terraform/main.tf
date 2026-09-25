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
