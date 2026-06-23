output "cluster_id" {
  description = "ID del cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "alb_dns_name" {
  description = "DNS del ALB para smoke tests y acceso externo"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN del ALB"
  value       = aws_lb.main.arn
}

output "service_names" {
  description = "Nombres de los ECS Services desplegados"
  value       = { for k, v in aws_ecs_service.services : k => v.name }
}

output "log_group_names" {
  description = "Nombres de los CloudWatch Log Groups por servicio"
  value       = { for k, v in aws_cloudwatch_log_group.services : k => v.name }
}

output "alb_arn_suffix" {
  description = "ARN suffix del ALB para métricas CloudWatch"
  value       = aws_lb.main.arn_suffix
}

output "cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}
