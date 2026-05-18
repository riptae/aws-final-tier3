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

module "database" {
  source      = "../modules/database"
  name_prefix = local.name_prefix
  common_tags = local.common_tags

  private_db_subnet_ids = module.network.private_db_subnet_ids
  db_sg_id              = module.security.db_sg_id
  db_password           = var.db_password
}

module "monitoring" {
  source = "../modules/monitoring"

  name_prefix = local.name_prefix
  common_tags = local.common_tags

  notification_email = var.notification_email

  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  web_instance_ids        = module.compute.web_instance_ids
  app_instance_ids        = module.compute.app_instance_ids
  db_instance_id = module.database.db_instance_id
}