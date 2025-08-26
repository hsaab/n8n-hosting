# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# These outputs provide important information about the deployed infrastructure
# ---------------------------------------------------------------------------------------------------------------------

# ALB DNS name for accessing n8n
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.n8n.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.n8n.zone_id
}

# ECS Cluster information
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.n8n.name
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.n8n.id
}

# RDS Database information
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.n8n.endpoint
  sensitive   = false
}

output "rds_address" {
  description = "RDS instance hostname/address"
  value       = aws_db_instance.n8n.address
  sensitive   = false
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.n8n.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.n8n.db_name
}

# EFS information
output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.n8n_storage.id
}

# Secrets Manager
output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.n8n_secrets.arn
  sensitive   = true
}

# Service Discovery
output "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  value       = aws_service_discovery_private_dns_namespace.n8n.id
}

# Instructions for connecting
output "connection_instructions" {
  description = "Instructions for connecting to n8n"
  value = <<-EOT
    Your n8n instance has been deployed with the following configuration:

    📋 Application Access:
    - Load Balancer: ${aws_lb.n8n.dns_name}
    - Access your n8n instance at: http://${aws_lb.n8n.dns_name}
    
    🗄️  Database (RDS PostgreSQL):
    - Endpoint: ${aws_db_instance.n8n.endpoint}
    - Database: ${aws_db_instance.n8n.db_name}
    - Port: ${aws_db_instance.n8n.port}
    
    📁 Storage:
    - EFS File System ID: ${aws_efs_file_system.n8n_storage.id}
    - Used for: n8n application data and Redis persistence
    
    🔐 Secrets:
    - Stored in AWS Secrets Manager: ${aws_secretsmanager_secret.n8n_secrets.name}
    
    ⚙️  ECS Resources:
    - Cluster: ${aws_ecs_cluster.n8n.name}
    - Services: n8n, n8n-worker, redis
    - Database: Managed by RDS (no longer containerized)
    
    🚀 Next Steps:
    1. If using a custom domain, create CNAME record pointing to the load balancer
    2. Configure SSL certificate in ALB if needed
    3. Access n8n and complete initial setup
  EOT
}