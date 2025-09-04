# =============================================================================
# SECURITY MODULE OUTPUTS
# =============================================================================

# Security Group IDs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_instance_security_group_id" {
  description = "ID of the ECS instance security group"
  value       = aws_security_group.ec2_instances.id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis.id
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

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance.name
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