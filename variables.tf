variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo para nombrar todos los recursos"
  type        = string
  default     = "a5iac-moodle"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Para ALB y tareas de ECS (una por AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Para RDS y ElastiCache (una por AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "app_port" {
  description = "Puerto en el que escucha el contenedor de Moodle"
  type        = number
  default     = 8080
}

variable "db_name" {
  type    = string
  default = "moodle"
}

variable "db_username" {
  type    = string
  default = "moodleadmin"
}

variable "db_password" {
  description = "Contraseña de RDS (va en terraform.tfvars, que NO se sube a git)"
  type        = string
  sensitive   = true
}
