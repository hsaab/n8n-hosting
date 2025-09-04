# =============================================================================
# STORAGE MODULE OUTPUTS
# =============================================================================

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.n8n.address
}

output "rds_address" {
  description = "RDS instance address"
  value       = aws_db_instance.n8n.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.n8n.port
}

output "rds_db_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.n8n.identifier
}

# Redis Outputs
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_cluster_id" {
  description = "ElastiCache cluster ID"
  value       = aws_elasticache_cluster.redis.cluster_id
}

# EFS Outputs
output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.n8n_storage.id
}

output "efs_file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.n8n_storage.arn
}

output "efs_access_point_id" {
  description = "EFS access point ID"
  value       = aws_efs_access_point.n8n_data.id
}

output "efs_access_point_arn" {
  description = "EFS access point ARN"
  value       = aws_efs_access_point.n8n_data.arn
}