locals {
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
        cidr = cidr
        az = var.azs[idx]
        name = "${var.name_prefix}-public-${idx + 1}"
    }
  }

  private_web_subnets = {
    for idx, cidr in var.private_web_subnet_cidrs :
    idx => {
        cidr = cidr
        az = var.azs[idx]
        name = "${var.name_prefix}-private-web-${idx + 1}"
    }
  }

  private_app_subnets = {
    for idx, cidr in var.private_app_subnet_cidrs :
    idx => {
        cidr = cidr
        az = var.azs[idx]
        name = "${var.name_prefix}-private-app-${idx + 1}"
    }
  }

  private_db_subnets = {
    for idx, cidr in var.private_db_subnet_cidrs :
    idx => {
        cidr = cidr
        az = var.azs[idx]
        name = "${var.name_prefix}-private-db-${idx + 1}"
    }
  }
}