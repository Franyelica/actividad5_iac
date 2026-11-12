output "db_host" {
  description = "Host de RDS sin el puerto"
  value       = aws_db_instance.this.address
}

output "redis_host" {
  description = "Endpoint primario de Valkey"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}
