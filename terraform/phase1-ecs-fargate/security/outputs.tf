# =============================================================================
# SECURITY MODULE OUTPUTS
# =============================================================================

# Security Group IDs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "n8n_security_group_id" {
  description = "ID of the N8N Fargate security group"
  value       = aws_security_group.n8n_fargate.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "efs_security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}

# IAM Role ARNs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# Secrets Manager
output "n8n_secrets_arn" {
  description = "ARN of the N8N secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.n8n_secrets.arn
}

output "n8n_secrets_name" {
  description = "Name of the N8N secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.n8n_secrets.name
}