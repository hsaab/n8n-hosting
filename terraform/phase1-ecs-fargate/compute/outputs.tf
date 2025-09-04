# =============================================================================
# COMPUTE MODULE OUTPUTS - FARGATE
# =============================================================================

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.n8n.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.n8n.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.n8n.arn
}

# ECS Service Outputs
output "ecs_service_name" {
  description = "N8N ECS service name"
  value       = aws_ecs_service.n8n.name
}

output "ecs_service_arn" {
  description = "N8N ECS service ARN"
  value       = aws_ecs_service.n8n.id
}

output "n8n_task_definition_arn" {
  description = "N8N task definition ARN"
  value       = aws_ecs_task_definition.n8n.arn
}