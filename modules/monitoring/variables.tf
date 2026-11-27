variable "project_name" { type = string }
variable "aws_region" { type = string }

variable "alert_email" {
  description = "Correo que recibe las alertas (hay que confirmar la suscripcion de SNS)"
  type        = string
}

# ---- Datos que vienen de los otros modulos ----
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "log_group_name" { type = string }
variable "db_instance_id" { type = string }
variable "cache_cluster_id" { type = string }

# ---- Umbrales ----
variable "http_5xx_percent_threshold" {
  type    = number
  default = 5
}

variable "cpu_percent_threshold" {
  type    = number
  default = 85
}

variable "memory_percent_threshold" {
  type    = number
  default = 85
}

variable "db_connections_threshold" {
  description = "db.t3.micro soporta unas ~60 conexiones"
  type        = number
  default     = 50
}

variable "db_free_storage_bytes_threshold" {
  description = "Alerta cuando quedan menos de 2 GB de los 20 GB asignados"
  type        = number
  default     = 2000000000
}
