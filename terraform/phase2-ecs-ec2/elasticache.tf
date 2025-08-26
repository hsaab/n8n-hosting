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

# Security group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = "${var.cluster_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Allow inbound from ECS tasks
  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-elasticache-sg"
  }
}

# ElastiCache Replication Group (Redis cluster)
resource "aws_elasticache_replication_group" "n8n_redis" {
  replication_group_id         = "${var.cluster_name}-redis"
  description                  = "Redis cluster for n8n queue management"
  
  # Instance configuration
  node_type                    = var.redis_node_type
  port                         = 6379
  parameter_group_name         = var.redis_parameter_group
  
  # High availability configuration
  num_cache_clusters           = var.redis_num_cache_clusters
  automatic_failover_enabled   = var.redis_num_cache_clusters > 1
  multi_az_enabled            = var.redis_num_cache_clusters > 1
  
  # Network configuration
  subnet_group_name           = aws_elasticache_subnet_group.n8n_redis.name
  security_group_ids          = [aws_security_group.elasticache.id]
  
  # Security configuration
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = var.redis_transit_encryption
  auth_token                  = var.redis_auth_token != "" ? var.redis_auth_token : null
  
  # Maintenance and backup
  maintenance_window          = var.redis_maintenance_window
  snapshot_retention_limit    = var.redis_snapshot_retention
  snapshot_window            = var.redis_snapshot_window
  
  # Monitoring
  notification_topic_arn      = var.redis_notification_topic_arn
  
  # Engine version
  engine_version             = var.redis_engine_version
  
  # Auto-upgrade
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade

  # Final snapshot
  final_snapshot_identifier = "${var.cluster_name}-redis-final-snapshot"

  tags = {
    Name = "${var.cluster_name}-redis"
  }

  lifecycle {
    ignore_changes = [auth_token]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARMS FOR ELASTICACHE
# Monitor Redis performance and availability
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "redis_cpu_utilization" {
  alarm_name          = "${var.cluster_name}-redis-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors redis cpu utilization"
  alarm_actions       = var.redis_notification_topic_arn != "" ? [var.redis_notification_topic_arn] : []

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.n8n_redis.cache_cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory_usage" {
  alarm_name          = "${var.cluster_name}-redis-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors redis memory usage"
  alarm_actions       = var.redis_notification_topic_arn != "" ? [var.redis_notification_topic_arn] : []

  dimensions = {
    CacheClusterId = aws_elasticache_replication_group.n8n_redis.cache_cluster_id
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "redis_endpoint" {
  description = "Redis primary endpoint for n8n configuration"
  value       = aws_elasticache_replication_group.n8n_redis.configuration_endpoint_address != "" ? aws_elasticache_replication_group.n8n_redis.configuration_endpoint_address : aws_elasticache_replication_group.n8n_redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.n8n_redis.port
}

output "redis_auth_token_required" {
  description = "Whether Redis requires auth token"
  value       = var.redis_auth_token != ""
  sensitive   = true
}