#############################
# BASTION INSTANCE
#############################

resource "aws_instance" "bastion" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  })
}

#############################
# WEB INSTANCE
#############################
resource "aws_instance" "web" {
  count = length(var.private_web_subnet_ids)

  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.private_web_subnet_ids[count.index]
  vpc_security_group_ids = [var.web_sg_id]
  
  associate_public_ip_address = false

  user_data = <<-EOF

  #!/bin/bash
  dnf update -y
  dnf install -y nginx
  systemctl enable nginx
  systemctl start nginx
  echo "WEB SERVER ${count.index + 1}" > /usr/share/nginx/html/index.html
  EOF

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-web-${count.index + 1}"
    Role = "web"
  })
}


#############################
# APP INSTANCE
#############################
resource "aws_instance" "app" {
  count = length(var.parivate_app_subnet_ids)

  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.parivate_app_subnet_ids[count.index]
  vpc_security_group_ids = [var.app_sg_id]
  associate_public_ip_address = false
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-${count.index + 1}"
    Role = "app"
  })
}