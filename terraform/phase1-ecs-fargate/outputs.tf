# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# These outputs provide important information about the deployed infrastructure
# ---------------------------------------------------------------------------------------------------------------------

# ALB DNS name for accessing n8n
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.networking.alb_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.networking.alb_zone_id
}

# ECS Cluster information
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.compute.ecs_cluster_id
}

# RDS Database information
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.storage.rds_endpoint
  sensitive   = false
}

output "rds_address" {
  description = "RDS instance hostname/address"
  value       = module.storage.rds_address
  sensitive   = false
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.storage.rds_port
}

# EFS information
output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = module.storage.efs_file_system_id
}

# Secrets Manager
output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.security.n8n_secrets_arn
  sensitive   = true
}

# Service Discovery
output "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  value       = module.networking.service_discovery_namespace_id
}

# Instructions for connecting
output "connection_instructions" {
  description = "Instructions for connecting to n8n"
  value = <<-EOT
    Your n8n instance has been deployed with the following configuration:

    📋 Application Access:
    - Load Balancer: ${module.networking.alb_dns_name}
    - Access your n8n instance at: http://${module.networking.alb_dns_name}
    
    🗄️  Database (RDS PostgreSQL):
    - Endpoint: ${module.storage.rds_endpoint}
    - Database: ${var.postgres_db}
    - Port: ${module.storage.rds_port}
    
    📁 Storage:
    - EFS File System ID: ${module.storage.efs_file_system_id}
    - Used for: n8n application data
    
    🔐 Secrets:
    - Stored in AWS Secrets Manager: ${module.security.n8n_secrets_name}
    
    ⚙️  ECS Resources:
    - Cluster: ${module.compute.ecs_cluster_name}
    - Service: n8n (Fargate)
    - Database: Managed by RDS (no longer containerized)
    
    🚀 Next Steps:
    1. If using a custom domain, create CNAME record pointing to the load balancer
    2. Configure SSL certificate in ALB if needed
    3. Access n8n and complete initial setup
  EOT
}