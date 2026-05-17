resource "aws_db_subnet_group" "this" {
  name = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-mysql"

    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    allocated_storage = 20
    storage_type = "gp3"

    db_name = var.db_name
    username = var.db_username
    password = var.db_password

    db_subnet_group_name = aws_db_subnet_group.this.name
    vpc_security_group_ids = [var.db_sg_id]

    multi_az = true
    publicly_accessible = false

    skip_final_snapshot = true
    deletion_protection = false

    backup_retention_period = 1

    tags = merge(var.common_tags, {
        Name = "${var.name_prefix}-mysql"
    })
}

