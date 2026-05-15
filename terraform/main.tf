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