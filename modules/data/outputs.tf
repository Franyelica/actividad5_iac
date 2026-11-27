output "db_host" {
  description = "Host de RDS sin el puerto"
  value       = aws_db_instance.this.address
}

output "redis_host" {
  description = "Endpoint primario de Valkey"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

# ---- Para el modulo de monitoreo ----
output "db_instance_id" {
  value = aws_db_instance.this.identifier
}

output "cache_cluster_id" {
  description = "Id del unico nodo (num_cache_clusters = 1); es la dimension de las metricas"
  value       = tolist(aws_elasticache_replication_group.this.member_clusters)[0]
}
