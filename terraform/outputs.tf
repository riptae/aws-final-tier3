output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "db_endpoint" {
  value     = module.database.db_endpoint
  sensitive = true
}

output "dashboard_name" {
  value = module.dashboard.dashboard_name
}