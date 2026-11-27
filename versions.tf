terraform {
  required_version = ">= 1.10.0"

  # Estado remoto en S3 (lo crea bootstrap/). Configuracion parcial: el bucket se
  # pasa con -backend-config para no dejar el numero de cuenta escrito en el repo.
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    key          = "moodle/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}
