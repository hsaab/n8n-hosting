# =============================================================================
# NETWORKING MODULE OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the existing VPC"
  value       = var.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.private_subnet_ids
}

# ALB Outputs
output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.n8n.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.n8n.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = aws_lb.n8n.arn_suffix
}

# ALB DNS name and zone ID are already defined in alb.tf

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.n8n.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group (for monitoring)"
  value       = aws_lb_target_group.n8n.arn_suffix
}

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.n8n.id
}

output "service_discovery_n8n_service_id" {
  description = "ID of the n8n service discovery service"
  value       = aws_service_discovery_service.n8n.id
}