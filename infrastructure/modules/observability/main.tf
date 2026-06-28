locals {
  services = ["catalog", "cart", "checkout", "orders", "ui", "admin"]
}

data "aws_region" "current" {}

# ─── CloudWatch Dashboard ─────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "RetailStore-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [

      # ── Header: identifica el entorno ──
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# 🏪 RetailStore — Entorno: **${upper(var.environment)}**\nCluster ECS: `${var.ecs_cluster_name}` | RDS: `${var.rds_instance_id}` | Redis: `${var.redis_cluster_id}` | Región: `${data.aws_region.current.name}`"
        }
      },

      # ══════════ SECCIÓN ECS ══════════
      {
        type   = "text"
        x      = 0
        y      = 2
        width  = 24
        height = 1
        properties = { markdown = "## 🐳 ECS — Cómputo" }
      },

      # ECS CPU por servicio
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] CPU Utilization por servicio (%)"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ECS", "CPUUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
          annotations = {
            horizontal = [{ value = 80, label = "Umbral alarma 80%", color = "#d62728" }]
          }
          yAxis = { left = { min = 0, max = 100 } }
        }
      },

      # ECS Memoria por servicio
      {
        type   = "metric"
        x      = 12
        y      = 3
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Memory Utilization por servicio (%)"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ECS", "MemoryUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
          annotations = {
            horizontal = [{ value = 80, label = "Umbral alarma 80%", color = "#d62728" }]
          }
          yAxis = { left = { min = 0, max = 100 } }
        }
      },

      # ECS Tareas corriendo
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Tareas corriendo por servicio"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          stat   = "Average"
          metrics = [
            for svc in local.services : [
              "AWS/ECS", "RunningTaskCount",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
          yAxis = { left = { min = 0 } }
          annotations = {
            horizontal = [{ value = 1, label = "Mínimo esperado", color = "#ff7f0e", fill = "below" }]
          }
        }
      },

      # ECS CPU actual (singlevalue)
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          title     = "[${upper(var.environment)}] CPU actual por servicio"
          region    = data.aws_region.current.name
          view      = "singleValue"
          period    = 60
          stat      = "Average"
          sparkline = true
          metrics = [
            for svc in local.services : [
              "AWS/ECS", "CPUUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", "${var.ecs_cluster_name}-${svc}",
              { label = svc }
            ]
          ]
        }
      },

      # ══════════ SECCIÓN ALB ══════════
      {
        type   = "text"
        x      = 0
        y      = 15
        width  = 24
        height = 1
        properties = { markdown = "## ⚖️ ALB — Tráfico y Errores" }
      },

      # Requests y errores HTTP
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Requests totales y errores HTTP"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount",              "LoadBalancer", var.alb_arn_suffix, { label = "Total",  stat = "Sum", color = "#1f77b4" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "5xx",    stat = "Sum", color = "#d62728" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "4xx",    stat = "Sum", color = "#ff7f0e" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.alb_arn_suffix, { label = "2xx OK", stat = "Sum", color = "#2ca02c" }]
          ]
        }
      },

      # Latencia p50 / p95 / p99
      {
        type   = "metric"
        x      = 12
        y      = 16
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Latencia ALB (p50 / p95 / p99)"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { label = "p50", stat = "p50", color = "#2ca02c" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { label = "p95", stat = "p95", color = "#ff7f0e" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { label = "p99", stat = "p99", color = "#d62728" }]
          ]
          annotations = {
            horizontal = [{ value = 2, label = "SLO 2s", color = "#d62728" }]
          }
          yAxis = { left = { min = 0 } }
        }
      },

      # Healthy / Unhealthy hosts
      {
        type   = "metric"
        x      = 0
        y      = 22
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Hosts Healthy vs Unhealthy por Target Group"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HealthyHostCount\" AND LoadBalancer=\"${var.alb_arn_suffix}\"', 'Minimum', 60)", id = "healthy",   label = "Healthy",   color = "#2ca02c" }],
            [{ expression = "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\" AND LoadBalancer=\"${var.alb_arn_suffix}\"', 'Maximum', 60)", id = "unhealthy", label = "Unhealthy", color = "#d62728" }]
          ]
          yAxis = { left = { min = 0 } }
        }
      },

      # Conexiones ALB
      {
        type   = "metric"
        x      = 12
        y      = 22
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Conexiones ALB activas y rechazadas"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount",   "LoadBalancer", var.alb_arn_suffix, { label = "Activas",    stat = "Sum" }],
            ["AWS/ApplicationELB", "RejectedConnectionCount", "LoadBalancer", var.alb_arn_suffix, { label = "Rechazadas", stat = "Sum", color = "#d62728" }],
            ["AWS/ApplicationELB", "NewConnectionCount",      "LoadBalancer", var.alb_arn_suffix, { label = "Nuevas",     stat = "Sum", color = "#17becf" }]
          ]
        }
      },

      # ══════════ SECCIÓN RDS ══════════
      {
        type   = "text"
        x      = 0
        y      = 28
        width  = 24
        height = 1
        properties = { markdown = "## 🗄️ RDS PostgreSQL — Base de Datos" }
      },

      # RDS CPU + Conexiones
      {
        type   = "metric"
        x      = 0
        y      = 29
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] RDS CPU y Conexiones activas"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/RDS", "CPUUtilization",      "DBInstanceIdentifier", var.rds_instance_id, { label = "CPU %",      stat = "Average", color = "#1f77b4", yAxis = "left" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id, { label = "Conexiones", stat = "Average", color = "#ff7f0e", yAxis = "right" }]
          ]
          yAxis = {
            left  = { label = "CPU %",      min = 0, max = 100 }
            right = { label = "Conexiones", min = 0 }
          }
          annotations = {
            horizontal = [{ value = 80, label = "CPU umbral 80%", color = "#d62728", yAxis = "left" }]
          }
        }
      },

      # RDS Memoria y Storage libres
      {
        type   = "metric"
        x      = 12
        y      = 29
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] RDS Memoria y Storage libre"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/RDS", "FreeableMemory",   "DBInstanceIdentifier", var.rds_instance_id, { label = "Memoria libre (bytes)", stat = "Average", color = "#2ca02c" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id, { label = "Storage libre (bytes)", stat = "Average", color = "#17becf" }]
          ]
          annotations = {
            horizontal = [{ value = 1073741824, label = "Mínimo 1 GB", color = "#d62728" }]
          }
        }
      },

      # RDS Latencia Read/Write
      {
        type   = "metric"
        x      = 0
        y      = 35
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] RDS Latencia Read/Write"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/RDS", "ReadLatency",  "DBInstanceIdentifier", var.rds_instance_id, { label = "Read latency",  stat = "Average", color = "#2ca02c" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", var.rds_instance_id, { label = "Write latency", stat = "Average", color = "#ff7f0e" }]
          ]
        }
      },

      # RDS IOPS
      {
        type   = "metric"
        x      = 12
        y      = 35
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] RDS IOPS"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/RDS", "ReadIOPS",  "DBInstanceIdentifier", var.rds_instance_id, { label = "Read IOPS",  stat = "Average", color = "#1f77b4" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", var.rds_instance_id, { label = "Write IOPS", stat = "Average", color = "#ff7f0e" }]
          ]
        }
      },

      # ══════════ SECCIÓN REDIS ══════════
      {
        type   = "text"
        x      = 0
        y      = 41
        width  = 24
        height = 1
        properties = { markdown = "## ⚡ ElastiCache Redis — Caché" }
      },

      # Redis CPU + Conexiones
      {
        type   = "metric"
        x      = 0
        y      = 42
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Redis CPU y Conexiones"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", var.redis_cluster_id, { label = "Engine CPU %", stat = "Average", color = "#1f77b4", yAxis = "left" }],
            ["AWS/ElastiCache", "CurrConnections",      "CacheClusterId", var.redis_cluster_id, { label = "Conexiones",   stat = "Average", color = "#ff7f0e", yAxis = "right" }]
          ]
          yAxis = {
            left  = { label = "CPU %",      min = 0, max = 100 }
            right = { label = "Conexiones", min = 0 }
          }
        }
      },

      # Redis Hit vs Miss
      {
        type   = "metric"
        x      = 12
        y      = 42
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Redis Cache Hit vs Miss"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ElastiCache", "CacheHits",   "CacheClusterId", var.redis_cluster_id, { label = "Cache Hits",   stat = "Sum", color = "#2ca02c" }],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", var.redis_cluster_id, { label = "Cache Misses", stat = "Sum", color = "#d62728" }]
          ]
        }
      },

      # Redis Memoria
      {
        type   = "metric"
        x      = 0
        y      = 48
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Redis Memoria usada y disponible"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ElastiCache", "BytesUsedForCache", "CacheClusterId", var.redis_cluster_id, { label = "Usado (bytes)", stat = "Average", color = "#ff7f0e" }],
            ["AWS/ElastiCache", "FreeableMemory",    "CacheClusterId", var.redis_cluster_id, { label = "Libre (bytes)", stat = "Average", color = "#2ca02c" }]
          ]
        }
      },

      # Redis Comandos/s
      {
        type   = "metric"
        x      = 12
        y      = 48
        width  = 12
        height = 6
        properties = {
          title  = "[${upper(var.environment)}] Redis Comandos por segundo"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/ElastiCache", "GetTypeCmds", "CacheClusterId", var.redis_cluster_id, { label = "GET/s", stat = "Average", color = "#1f77b4" }],
            ["AWS/ElastiCache", "SetTypeCmds", "CacheClusterId", var.redis_cluster_id, { label = "SET/s", stat = "Average", color = "#ff7f0e" }]
          ]
        }
      },

      # ══════════ SECCIÓN LOGS ══════════
      {
        type   = "text"
        x      = 0
        y      = 54
        width  = 24
        height = 1
        properties = { markdown = "## 📋 Logs — Errores recientes" }
      },

      {
        type   = "log"
        x      = 0
        y      = 55
        width  = 24
        height = 8
        properties = {
          title  = "[${upper(var.environment)}] Errores en todos los servicios"
          region = data.aws_region.current.name
          view   = "table"
          query  = "SOURCE '/retailstore/${var.environment}/catalog' | SOURCE '/retailstore/${var.environment}/cart' | SOURCE '/retailstore/${var.environment}/checkout' | SOURCE '/retailstore/${var.environment}/orders' | SOURCE '/retailstore/${var.environment}/ui' | SOURCE '/retailstore/${var.environment}/admin' | filter @message like /(?i)(error|exception|fatal|panic)/ | fields @timestamp, @logStream, @message | sort @timestamp desc | limit 50"
        }
      }
    ]
  })
}

# ─── Alarmas ─────────────────────────────────────────────────────────────────

# ALB — errores 5xx
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "retailstore-${var.environment}-alb-5xx-high"
  alarm_description   = "[${upper(var.environment)}] Errores 5xx en ALB superan 10 en 5 min"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-5xx-alarm" })
}

# ALB — latencia p99
resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "retailstore-${var.environment}-alb-latency-high"
  alarm_description   = "[${upper(var.environment)}] Latencia p99 ALB supera 2 segundos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p99"
  threshold           = 2
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-latency-alarm" })
}

# ALB — hosts unhealthy
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "retailstore-${var.environment}-unhealthy-hosts"
  alarm_description   = "[${upper(var.environment)}] Hosts unhealthy detectados en ALB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-unhealthy-hosts-alarm" })
}

# ECS — CPU alto por servicio
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = toset(local.services)

  alarm_name          = "retailstore-${var.environment}-${each.key}-cpu-high"
  alarm_description   = "[${upper(var.environment)}] CPU del servicio ${each.key} supera 80%"
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
    ServiceName = "${var.ecs_cluster_name}-${each.key}"
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-${each.key}-cpu-alarm", Service = each.key })
}

# ECS — Memoria alta por servicio
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = toset(local.services)

  alarm_name          = "retailstore-${var.environment}-${each.key}-memory-high"
  alarm_description   = "[${upper(var.environment)}] Memoria del servicio ${each.key} supera 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${var.ecs_cluster_name}-${each.key}"
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-${each.key}-memory-alarm", Service = each.key })
}

# ECS — sin tareas corriendo
resource "aws_cloudwatch_metric_alarm" "ecs_no_tasks" {
  for_each = toset(local.services)

  alarm_name          = "retailstore-${var.environment}-${each.key}-no-tasks"
  alarm_description   = "[${upper(var.environment)}] Servicio ${each.key} tiene 0 tareas corriendo"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "${var.ecs_cluster_name}-${each.key}"
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-${each.key}-no-tasks-alarm", Service = each.key })
}

# RDS — CPU alto
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "retailstore-${var.environment}-rds-cpu-high"
  alarm_description   = "[${upper(var.environment)}] CPU de RDS supera 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.rds_instance_id }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-rds-cpu-alarm" })
}

# RDS — storage bajo (< 2 GB)
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "retailstore-${var.environment}-rds-storage-low"
  alarm_description   = "[${upper(var.environment)}] Storage libre de RDS por debajo de 2 GB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648
  treat_missing_data  = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.rds_instance_id }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-rds-storage-alarm" })
}

# RDS — conexiones altas (> 100)
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "retailstore-${var.environment}-rds-connections-high"
  alarm_description   = "[${upper(var.environment)}] Conexiones a RDS superan 100"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.rds_instance_id }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-rds-connections-alarm" })
}

# Redis — CPU alto
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "retailstore-${var.environment}-redis-cpu-high"
  alarm_description   = "[${upper(var.environment)}] CPU de Redis supera 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = { CacheClusterId = var.redis_cluster_id }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-redis-cpu-alarm" })
}

# Redis — memoria baja (< 50 MB)
resource "aws_cloudwatch_metric_alarm" "redis_memory_low" {
  alarm_name          = "retailstore-${var.environment}-redis-memory-low"
  alarm_description   = "[${upper(var.environment)}] Memoria libre de Redis por debajo de 50 MB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 52428800
  treat_missing_data  = "notBreaching"

  dimensions = { CacheClusterId = var.redis_cluster_id }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-redis-memory-alarm" })
}
