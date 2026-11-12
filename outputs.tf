# ---- Contrato que consume el módulo de cómputo (ECS) ----
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "alb_sg_id" {
  value = module.network.alb_sg_id
}

output "app_sg_id" {
  value = module.network.app_sg_id
}

output "db_host" {
  value = module.data.db_host
}

output "db_name" {
  value = var.db_name
}

output "db_username" {
  value = var.db_username
}

output "redis_host" {
  value = module.data.redis_host
}
