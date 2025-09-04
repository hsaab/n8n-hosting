# =============================================================================
# MONITORING MODULE OUTPUTS
# =============================================================================

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.n8n.dashboard_name
}

output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.n8n.dashboard_arn
}

# Note: Log group outputs are now in the compute module