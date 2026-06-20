output "alb_dns_name" {
  description = "DNS del ALB — usar como base URL para smoke tests"
  value       = module.ecs.alb_dns_name
}

output "ecr_repository_urls" {
  description = "URLs de repositorios ECR por servicio"
  value       = module.ecr.repository_urls
}

output "db_secret_arn" {
  description = "ARN del secreto de RDS"
  value       = module.rds.db_secret_arn
  sensitive   = true
}
