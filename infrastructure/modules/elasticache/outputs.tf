output "redis_endpoint" {
  description = "Endpoint del cluster Redis"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "Puerto del cluster Redis"
  value       = aws_elasticache_cluster.main.port
}
