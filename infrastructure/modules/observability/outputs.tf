output "dashboard_name" {
  description = "Nombre del CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarm_arns" {
  description = "ARNs de todas las alarmas CloudWatch creadas"
  value = merge(
    { alb_5xx             = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn },
    { alb_latency         = aws_cloudwatch_metric_alarm.alb_latency_high.arn },
    { alb_unhealthy_hosts = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn },
    { rds_cpu             = aws_cloudwatch_metric_alarm.rds_cpu_high.arn },
    { rds_storage         = aws_cloudwatch_metric_alarm.rds_storage_low.arn },
    { rds_connections     = aws_cloudwatch_metric_alarm.rds_connections_high.arn },
    { redis_cpu           = aws_cloudwatch_metric_alarm.redis_cpu_high.arn },
    { redis_memory        = aws_cloudwatch_metric_alarm.redis_memory_low.arn },
    { for k, v in aws_cloudwatch_metric_alarm.ecs_cpu_high    : "ecs_cpu_${k}"    => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.ecs_memory_high : "ecs_memory_${k}" => v.arn },
    { for k, v in aws_cloudwatch_metric_alarm.ecs_no_tasks    : "ecs_notasks_${k}" => v.arn }
  )
}
