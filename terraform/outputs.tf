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

output "web_url" {
  description = "ALB HTTP address for browser and failover testing"
  value       = "http://${module.alb.alb_dns_name}"
}

output "dashboard_url" {
  value = module.dashboard.dashboard_url
}

output "web_unhealthy_alarm_name" {
  value = module.monitoring.web_unhealthy_alarm_name
}

output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}
