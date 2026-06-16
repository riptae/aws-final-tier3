project_name = "tier3-observability"
env          = "dev"
aws_region   = "ap-northeast-2"

vpc_cidr = "10.7.0.0/16"

azs = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

public_subnet_cidrs = [
  "10.7.1.0/24",
  "10.7.2.0/24"
]

private_web_subnet_cidrs = [
  "10.7.11.0/24",
  "10.7.12.0/24"
]

private_app_subnet_cidrs = [
  "10.7.21.0/24",
  "10.7.22.0/24"
]

private_db_subnet_cidrs = [
  "10.7.31.0/24",
  "10.7.32.0/24"
]

my_ip_cidr = "0.0.0.0/32"

######################
# COMPUTE
######################
ami_id        = "ami-09354ec74df2f0354" // amz linux
instance_type = "t3.micro"

######################
# DATABASE
######################
db_password = "Password123!"

######################
# MONITORING
######################
notification_email = "fruitunion1143@gmail.com"

######################
# DNS
######################
domain_name = "test-test-test.example.com"