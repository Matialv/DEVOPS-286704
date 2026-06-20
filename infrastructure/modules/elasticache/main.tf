data "aws_iam_role" "labrole" {
  name = "LabRole"
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "retailstore-${var.environment}-redis-subnet"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "retailstore-${var.environment}-redis-subnet" })
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "retailstore-${var.environment}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.sg_redis_id]

  tags = merge(var.tags, { Name = "retailstore-${var.environment}-redis" })
}
