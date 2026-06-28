output "redis_endpoint" {
  description = "Endpoint del cluster Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto del cluster Redis"
  value       = aws_elasticache_cluster.main.port
}

output "redis_cluster_id" {
  description = "ID del cluster ElastiCache para métricas CloudWatch"
  value       = aws_elasticache_cluster.main.cluster_id
}
