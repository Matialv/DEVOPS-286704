output "db_endpoint" {
  description = "Endpoint de conexión a RDS"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN del secreto de credenciales en Secrets Manager"
  value       = data.aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Nombre del secreto en Secrets Manager"
  value       = data.aws_secretsmanager_secret.db.name
}
