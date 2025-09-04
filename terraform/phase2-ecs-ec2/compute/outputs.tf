# =============================================================================
# COMPUTE MODULE OUTPUTS
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

# Auto Scaling Group Outputs
output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.ecs_instances.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.ecs_instances.arn
}

# ECS Service Outputs
output "n8n_service_name" {
  description = "N8N ECS service name"
  value       = aws_ecs_service.n8n.name
}

output "n8n_service_arn" {
  description = "N8N ECS service ARN"
  value       = aws_ecs_service.n8n.id
}

output "n8n_task_definition_arn" {
  description = "N8N task definition ARN"
  value       = aws_ecs_task_definition.n8n.arn
}

# Launch Template Outputs
output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.ecs_instances.id
}

output "launch_template_latest_version" {
  description = "Launch template latest version"
  value       = aws_launch_template.ecs_instances.latest_version
}