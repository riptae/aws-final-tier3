output "bastion_instance_ip" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "web_instance_ids" {
  value = aws_instance.web[*].id
}

output "web_private_ips" {
  value = aws_instance.web[*].private_ip
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "app_private_ips" {
  value = aws_instance.app[*].private_ip
}