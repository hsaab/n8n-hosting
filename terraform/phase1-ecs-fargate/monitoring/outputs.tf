# =============================================================================
# MONITORING MODULE OUTPUTS - FARGATE
# =============================================================================

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.n8n.dashboard_name
}

output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.n8n.dashboard_arn
}

# Log Group Outputs
output "n8n_log_group_name" {
  description = "Name of the N8N log group"
  value       = aws_cloudwatch_log_group.n8n.name
}