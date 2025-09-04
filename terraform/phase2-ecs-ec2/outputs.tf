# =============================================================================
# ROOT LEVEL OUTPUTS
# =============================================================================

# Application Access
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

output "n8n_url" {
  description = "URL to access N8N application"
  value       = var.certificate_arn != "" ? "https://${module.networking.alb_dns_name}" : "http://${module.networking.alb_dns_name}"
}

# Networking
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# ECS Cluster
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.compute.ecs_cluster_arn
}

# Database
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.storage.rds_endpoint
  sensitive   = true
}

# Redis
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.storage.redis_endpoint
  sensitive   = true
}

# Security
output "n8n_secrets_arn" {
  description = "ARN of the N8N secrets in AWS Secrets Manager"
  value       = module.security.n8n_secrets_arn
}

# Monitoring
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.cloudwatch_dashboard_name
}