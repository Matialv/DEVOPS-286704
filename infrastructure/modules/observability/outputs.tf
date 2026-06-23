output "dashboard_name" {
  description = "Nombre del CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarm_arns" {
  description = "ARNs de las alarmas CloudWatch creadas"
  value = merge(
    { alb_5xx        = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn },
    { alb_latency    = aws_cloudwatch_metric_alarm.alb_latency_high.arn },
    { unhealthy_hosts = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn },
    { for k, v in aws_cloudwatch_metric_alarm.ecs_cpu_high : "cpu_${k}" => v.arn }
  )
}
