locals {
  services = ["catalog", "cart", "checkout", "orders", "ui", "admin"]
}

# ─── CloudWatch Dashboard ─────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "RetailStore-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # ── ECS CPU por servicio ──
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilization por servicio"
          view   = "timeSeries"
          period = 300
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
        }
      },
      # ── ECS Memoria por servicio ──
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilization por servicio"
          view   = "timeSeries"
          period = 300
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
        }
      },
      # ── ALB Request Count ──
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          view   = "timeSeries"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Total Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5xx Errors", color = "#d62728" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4xx Errors", color = "#ff7f0e" }]
          ]
        }
      },
      # ── ALB Latencia ──
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time (ms)"
          view   = "timeSeries"
          period = 60
          stat   = "p99"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { label = "p99 latency" }]
          ]
        }
      },
      # ── Healthy / Unhealthy hosts ──
      {
        type   = "metric"
        width  = 24
        height = 4
        properties = {
          title  = "ALB Healthy vs Unhealthy Hosts"
          view   = "singleValue"
          period = 60
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer", var.alb_arn_suffix,
              { label = "${svc} healthy" }
            ]
          ]
        }
      }
    ]
  })
}

# ─── Alarma 1: Alta tasa de errores 5xx en ALB ───────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "retailstore-${var.environment}-alb-5xx-high"
  alarm_description   = "Tasa de errores 5xx en ALB supera umbral"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-5xx-alarm" })
}

# ─── Alarma 2: CPU elevado en ECS ────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = toset(local.services)

  alarm_name          = "retailstore-${var.environment}-${each.key}-cpu-high"
  alarm_description   = "CPU del servicio ${each.key} supera 80% por 10 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "retailstore-${var.environment}-${each.key}"
  }

  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, {
    Name    = "retailstore-${var.environment}-${each.key}-cpu-alarm"
    Service = each.key
  })
}

# ─── Alarma 3: Latencia alta en ALB ─────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "retailstore-${var.environment}-alb-latency-high"
  alarm_description   = "Latencia p99 del ALB supera 2 segundos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 2
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-latency-alarm" })
}

# ─── Alarma 4: Hosts unhealthy en ALB ────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "retailstore-${var.environment}-unhealthy-hosts"
  alarm_description   = "Hay hosts unhealthy en el ALB — posible falla de servicio"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-unhealthy-hosts-alarm" })
}
