output "alb_dns_name" {
  description = "DNS del ALB — usar como base URL para smoke tests"
  value       = module.ecs.alb_dns_name
}

output "db_endpoint" {
  description = "Endpoint de conexión a RDS PostgreSQL"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN del secreto de RDS"
  value       = module.rds.db_secret_arn
  sensitive   = true
}
