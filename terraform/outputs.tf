output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

output "web_private_ips" {
  value = module.compute.web_private_ips
}

output "app_private_ips" {
  value = module.compute.app_private_ips
}

output "db_address" {
  description = "MySQL hostname without port"
  value       = module.database.db_address
}

output "db_port" {
  value = module.database.db_port
}
