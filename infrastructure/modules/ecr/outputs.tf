output "repository_urls" {
  description = "URLs de los repositorios ECR por servicio"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "registry_id" {
  description = "ID del registro ECR (cuenta AWS)"
  value       = values(aws_ecr_repository.services)[0].registry_id
}
