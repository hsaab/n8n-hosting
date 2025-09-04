# =============================================================================
# NETWORKING MODULE OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.n8n.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.n8n.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.n8n.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.n8n[*].id
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

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.n8n.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.n8n.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.n8n.arn
}

output "alb_target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  value       = aws_lb_target_group.n8n.arn_suffix
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

output "service_discovery_n8n_worker_service_id" {
  description = "ID of the n8n worker service discovery service"
  value       = aws_service_discovery_service.n8n_worker.id
}