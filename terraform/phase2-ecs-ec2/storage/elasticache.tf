# ---------------------------------------------------------------------------------------------------------------------
# AWS ELASTICACHE REDIS
# Managed Redis service - replaces the Redis ECS task from Phase 1
# ---------------------------------------------------------------------------------------------------------------------

# ElastiCache subnet group - must be in private subnets
resource "aws_elasticache_subnet_group" "n8n_redis" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.cluster_name}-redis-subnet-group"
  }
}

# ElastiCache Redis cluster (single instance for simplicity)
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.cluster_name}-redis"
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.n8n_redis.name
  security_group_ids   = [var.redis_security_group_id]
  engine_version       = var.redis_engine_version

  # Security configuration
  # Note: Encryption options not available for single-node clusters

  tags = {
    Name = "${var.cluster_name}-redis"
  }
}