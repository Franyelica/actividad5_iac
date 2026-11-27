variable "project_name" { type = string }
variable "aws_region" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "app_port" { type = number }

# Datos que vienen del módulo data de Fran
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

variable "redis_host" { type = string }

# ---- REVISAR ----
variable "moodle_image" {
  description = "Imagen de Moodle en Docker Hub. VERIFICAR en la pagina de la imagen que el nombre y la etiqueta existen."
  type        = string
  default     = "oksigenia/moodle:latest"
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
