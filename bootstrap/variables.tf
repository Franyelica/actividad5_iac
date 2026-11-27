variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Mismo prefijo que el proyecto principal"
  type        = string
  default     = "a5iac-moodle"
}

variable "github_owner" {
  type    = string
  default = "Franyelica"
}

variable "github_repo" {
  type    = string
  default = "actividad5_iac"
}

variable "apply_branch" {
  description = "Unica rama que puede ejecutar apply"
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "false si la cuenta ya tiene el proveedor OIDC de GitHub"
  type        = bool
  default     = true
}
