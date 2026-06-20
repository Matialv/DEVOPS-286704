output "function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.ecr_scan_notifier.function_name
}

output "sns_topic_arn" {
  description = "ARN del SNS Topic de alertas de seguridad"
  value       = aws_sns_topic.security_alerts.arn
}
