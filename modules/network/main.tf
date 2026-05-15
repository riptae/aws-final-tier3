#################################
# vpc
#################################

resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = merge(
        var.common_tags,
        {
            Name = "${var.name_prefix}-vpc"
        }
    )
}

#################################
# public subnet for BASTION, ALB
#################################

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id = aws_vpc.this.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
        Name = each.value.name
        Tier = "public"
    }
  )
}

#################################
# private subnet for WEB
#################################

resource "aws_subnet" "private_web" {
    for_each = local.private_web_subnets

    vpc_id = aws_vpc.this.id
    cidr_block = each.value.cidr
    availability_zone = each.value.az
    map_public_ip_on_launch = false

    tags = merge(
        var.common_tags,
        {
            Name = each.value.name
            Tier = "web"
        }
    )
}

#################################
# private subnet for APP
#################################

resource "aws_subnet" "private_app" {
  for_each = local.private_app_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = each.value.name
      Tier = "app"
    }
  )
}

#################################
# private subnet for DB
#################################

resource "aws_subnet" "private_db" {
  for_each = local.private_db_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = each.value.name
      Tier = "db"
    }
  )
}

#################################
# PUBLIC subnet routing
#################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
        Name = "${var.name_prefix}-igw"
    }
  )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}

resource "aws_route" "public_default" {
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  route_table_id = aws_route_table.public_rt.id
}


#################################
# PRIVATE subnet routing
#################################

resource "aws_eip" "this" {
  domain = "vpc"
  tags = merge(
    var.common_tags,
    {
        Name = "${var.name_prefix}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    {
        Name = "${var.name_prefix}-nat-gw"
    }
  )
  
  depends_on = [ aws_internet_gateway.this ]
}




#################################
# private subnet
#################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.name_prefix}-private-rt"
    }
  )
}

resource "aws_route" "private_default" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_web" {
    for_each = aws_subnet.private_web

    subnet_id = each.value.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app" {
    for_each = aws_subnet.private_app

    subnet_id = each.value.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db" {
    for_each = aws_subnet.private_db

    subnet_id = each.value.id
    route_table_id = aws_route_table.private.id
}