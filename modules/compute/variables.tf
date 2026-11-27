variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "app_port" { type = number }

# Datos que vienen del módulo "data" de Fran
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

variable "redis_host" { type = string }

# ---- LO QUE SANTIAGO DEBE REVISAR ----
variable "moodle_image" {
  description = <<-EOT
    Imagen de Moodle en Docker Hub (verificada: oksigenia/moodle, etiqueta 4.5 existe, amd64).
    Se usa 4.5 LTS y no latest porque latest = Moodle 5.3, que exige MySQL 8.4+,
    y el RDS del modulo data usa MySQL 8.0 (Moodle 4.5 si lo soporta).
  EOT
  type        = string
  default     = "oksigenia/moodle:4.5"
}

variable "moodle_admin_user" {
  type    = string
  default = "admin"
}

variable "moodle_admin_password" {
  description = "Clave del admin de Moodle. Debe cumplir la politica de Moodle (mayuscula, numero, simbolo)."
  type        = string
  sensitive   = true
}

variable "task_cpu" {
  type    = number
  default = 1024
}

variable "task_memory" {
  type    = number
  default = 2048
}
