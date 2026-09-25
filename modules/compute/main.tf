#############################
# BASTION INSTANCE
#############################

resource "aws_instance" "bastion" {

  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  associate_public_ip_address = true

  ami = var.ami_id
  instance_type = var.instance_type

  user_data = templatefile(
  "${path.module}/templates/bastion-init.sh.tftpl", // template
  { // 변수
    inventory_b64 = base64encode(yamlencode({
      all = {
        vars = {
          ansible_user               = "ec2-user"
          ansible_python_interpreter = "/usr/bin/python3"
        }

        children = {
          web = {
            hosts = {
              for index, instance in aws_instance.web :
              "web${index + 1}" => {
                ansible_host = instance.private_ip
              }
            }
          }

          app = {
            hosts = {
              for index, instance in aws_instance.app :
              "app${index + 1}" => {
                ansible_host = instance.private_ip
              }
            }
          }
        }
      }
    }))

    # 각 Playbook과 설정 템플릿을 개별 전달한다.
    check_hosts_b64 = filebase64("${path.module}/deployment/playbooks/01-check-hosts.yml")
    setup_web_b64   = filebase64("${path.module}/deployment/playbooks/02-setup-web.yml")
    setup_app_b64   = filebase64("${path.module}/deployment/playbooks/03-setup-app.yml")
    deploy_app_b64  = filebase64("${path.module}/deployment/playbooks/04-deploy-app.yml")
    deploy_web_b64  = filebase64("${path.module}/deployment/playbooks/05-deploy-web.yml")
    nginx_b64       = filebase64("${path.module}/deployment/templates/nginx.conf.j2")
    app_service_b64 = filebase64("${path.module}/deployment/templates/app.service.j2")
  }
)
  
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
set -eu

echo 'ec2-user:password' | chpasswd

set -x
dnf update -y
dnf install -y nginx
systemctl enable --now nginx
echo "WEB SERVER ${count.index + 1}" > /usr/share/nginx/html/index.html

# SSH 서비스 시작 및 부팅 시 자동 실행
systemctl enable --now sshd

# 기존 설정보다 먼저 읽히도록 비밀번호 인증 설정
mkdir -p /etc/ssh/sshd_config.d
echo 'PasswordAuthentication yes' > /etc/ssh/sshd_config.d/00-password-auth.conf

# 위 설정 파일을 가장 먼저 읽도록 지정
sed -i '1i Include /etc/ssh/sshd_config.d/00-password-auth.conf' /etc/ssh/sshd_config
 
# 문법 검사 후 설정 반영
sshd -t
systemctl reload sshd

# 적용 결과 확인
sshd -T | grep '^passwordauthentication'
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

  user_data = <<-EOF
#!/bin/bash
set -eu

echo 'ec2-user:password' | chpasswd

set -x
dnf update -y

# SSH 서비스 시작 및 부팅 시 자동 실행
systemctl enable --now sshd

# 기존 설정보다 먼저 읽히도록 비밀번호 인증 설정
mkdir -p /etc/ssh/sshd_config.d
echo 'PasswordAuthentication yes' > /etc/ssh/sshd_config.d/00-password-auth.conf

# 위 설정 파일을 가장 먼저 읽도록 지정
sed -i '1i Include /etc/ssh/sshd_config.d/00-password-auth.conf' /etc/ssh/sshd_config
 
# 문법 검사 후 설정 반영
sshd -t
systemctl reload sshd

# 적용 결과 확인
sshd -T | grep '^passwordauthentication'
EOF
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-${count.index + 1}"
    Role = "app"
  })
}
