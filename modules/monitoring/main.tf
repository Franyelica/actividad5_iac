# ---------- Canal de notificacion ----------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# AWS envia un correo de confirmacion: hay que aceptarlo para recibir alertas.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# =====================================================================
# Politicas de alerta
# =====================================================================

# ---------- ALB / aplicacion ----------
# Equivalente al "uptime check": ningun contenedor sano detras del balanceador.
resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts" {
  alarm_name          = "${var.project_name}-sin-hosts-sanos"
  alarm_description   = "El balanceador no tiene ningun contenedor sano durante 2 minutos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# Errores 5xx sobre el total de peticiones, durante 5 minutos.
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${var.project_name}-errores-5xx"
  alarm_description   = "Mas del ${var.http_5xx_percent_threshold}% de las peticiones responden 5xx durante 5 minutos"
  evaluation_periods  = 5
  threshold           = var.http_5xx_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "rate"
    expression  = "IF(requests > 0, 100 * errors / requests, 0)"
    label       = "% errores 5xx"
    return_data = true
  }

  metric_query {
    id = "errors"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"

      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 60
      stat        = "Sum"

      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project_name}-latencia-alta"
  alarm_description   = "Tiempo de respuesta promedio mayor a 3 s durante 5 minutos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 3
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# ---------- ECS (contenedores) ----------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project_name}-ecs-cpu-alta"
  alarm_description   = "CPU del servicio ECS sobre ${var.cpu_percent_threshold}% durante 10 minutos"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${var.project_name}-ecs-memoria-alta"
  alarm_description   = "Memoria del servicio ECS sobre ${var.memory_percent_threshold}% durante 10 minutos"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.memory_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# ---------- RDS (base de datos relacional) ----------
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-alta"
  alarm_description   = "CPU de RDS sobre ${var.cpu_percent_threshold}% durante 10 minutos"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-conexiones-altas"
  alarm_description   = "Mas de ${var.db_connections_threshold} conexiones a RDS durante 10 minutos"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.db_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-poco-disco"
  alarm_description   = "Espacio libre de RDS por debajo de 2 GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.db_free_storage_bytes_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# ---------- ElastiCache (Valkey, base en memoria) ----------
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  alarm_name          = "${var.project_name}-cache-cpu-alta"
  alarm_description   = "CPU del motor Valkey sobre ${var.cpu_percent_threshold}% durante 10 minutos"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.cache_cluster_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  alarm_name          = "${var.project_name}-cache-memoria-alta"
  alarm_description   = "Memoria de Valkey sobre ${var.memory_percent_threshold}% durante 10 minutos"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.memory_percent_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.cache_cluster_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

# =====================================================================
# Dashboard
# =====================================================================
locals {
  alarm_arns = [
    aws_cloudwatch_metric_alarm.no_healthy_hosts.arn,
    aws_cloudwatch_metric_alarm.http_5xx.arn,
    aws_cloudwatch_metric_alarm.high_latency.arn,
    aws_cloudwatch_metric_alarm.ecs_cpu.arn,
    aws_cloudwatch_metric_alarm.ecs_memory.arn,
    aws_cloudwatch_metric_alarm.rds_cpu.arn,
    aws_cloudwatch_metric_alarm.rds_connections.arn,
    aws_cloudwatch_metric_alarm.rds_storage.arn,
    aws_cloudwatch_metric_alarm.cache_cpu.arn,
    aws_cloudwatch_metric_alarm.cache_memory.arn,
  ]

  alb_dim   = ["LoadBalancer", var.alb_arn_suffix]
  ecs_dims  = ["ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
  rds_dim   = ["DBInstanceIdentifier", var.db_instance_id]
  cache_dim = ["CacheClusterId", var.cache_cluster_id]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project_name}-observabilidad"

  dashboard_body = jsonencode({
    widgets = [
      # ---- Resumen ----
      {
        type       = "text", x = 0, y = 0, width = 24, height = 1
        properties = { markdown = "# Resumen: estado de alertas e incidentes" }
      },
      {
        type = "alarm", x = 0, y = 1, width = 24, height = 4
        properties = {
          title  = "Alarmas (incidentes abiertos)"
          alarms = local.alarm_arns
        }
      },

      # ---- Balanceador y aplicacion ----
      {
        type       = "text", x = 0, y = 5, width = 24, height = 1
        properties = { markdown = "# Frontend: balanceador (ALB)" }
      },
      {
        type = "metric", x = 0, y = 6, width = 8, height = 6
        properties = {
          title  = "Peticiones y errores 5xx"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"
          metrics = [
            concat(["AWS/ApplicationELB", "RequestCount"], local.alb_dim),
            concat(["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count"], local.alb_dim),
            concat(["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count"], local.alb_dim),
          ]
        }
      },
      {
        type = "metric", x = 8, y = 6, width = 8, height = 6
        properties = {
          title  = "Latencia (s)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            concat(["AWS/ApplicationELB", "TargetResponseTime"], local.alb_dim),
          ]
        }
      },
      {
        type = "metric", x = 16, y = 6, width = 8, height = 6
        properties = {
          title  = "Hosts sanos / no sanos"
          region = var.aws_region
          stat   = "Minimum"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix],
          ]
        }
      },

      # ---- Contenedores ----
      {
        type       = "text", x = 0, y = 12, width = 24, height = 1
        properties = { markdown = "# Backend: contenedores (ECS Fargate)" }
      },
      {
        type = "metric", x = 0, y = 13, width = 12, height = 6
        properties = {
          title  = "CPU y memoria (%)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            concat(["AWS/ECS", "CPUUtilization"], local.ecs_dims),
            concat(["AWS/ECS", "MemoryUtilization"], local.ecs_dims),
          ]
        }
      },
      {
        type = "log", x = 12, y = 13, width = 12, height = 6
        properties = {
          title  = "Logs de Moodle: errores recientes"
          region = var.aws_region
          view   = "table"
          query  = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | filter @message like /(?i)(error|fatal|exception)/ | sort @timestamp desc | limit 20"
        }
      },

      # ---- Persistencia ----
      {
        type       = "text", x = 0, y = 19, width = 24, height = 1
        properties = { markdown = "# Persistencia: RDS (MySQL) y ElastiCache (Valkey)" }
      },
      {
        type = "metric", x = 0, y = 20, width = 8, height = 6
        properties = {
          title  = "RDS: CPU (%) y conexiones"
          region = var.aws_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            concat(["AWS/RDS", "CPUUtilization"], local.rds_dim),
            concat(["AWS/RDS", "DatabaseConnections"], local.rds_dim, [{ yAxis = "right" }]),
          ]
        }
      },
      {
        type = "metric", x = 8, y = 20, width = 8, height = 6
        properties = {
          title  = "RDS: espacio libre y memoria libre (bytes)"
          region = var.aws_region
          stat   = "Minimum"
          period = 300
          view   = "timeSeries"
          metrics = [
            concat(["AWS/RDS", "FreeStorageSpace"], local.rds_dim),
            concat(["AWS/RDS", "FreeableMemory"], local.rds_dim),
          ]
        }
      },
      {
        type = "metric", x = 16, y = 20, width = 8, height = 6
        properties = {
          title  = "Valkey: CPU y memoria (%)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            concat(["AWS/ElastiCache", "EngineCPUUtilization"], local.cache_dim),
            concat(["AWS/ElastiCache", "DatabaseMemoryUsagePercentage"], local.cache_dim),
          ]
        }
      },
    ]
  })
}
