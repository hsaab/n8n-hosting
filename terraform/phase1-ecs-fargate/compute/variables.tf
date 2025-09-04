# =============================================================================
# COMPUTE MODULE VARIABLES - FARGATE
# =============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
}

variable "service_name" {
  description = "Name for the ECS service"
  type        = string
  default     = "n8n-service"
}

# Network Dependencies
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

# Security Dependencies
variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "n8n_security_group_id" {
  description = "Security group ID for N8N Fargate tasks"
  type        = string
}

variable "n8n_secrets_arn" {
  description = "ARN of the N8N secrets in Secrets Manager"
  type        = string
}

# Storage Dependencies
variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS access point ID"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

# N8N Configuration
variable "n8n_image_tag" {
  description = "N8N Docker image tag"
  type        = string
  default     = "latest"
}

variable "n8n_cpu" {
  description = "CPU units for N8N container"
  type        = number
  default     = 512
}

variable "n8n_memory" {
  description = "Memory (MB) for N8N container"
  type        = number
  default     = 1024
}

variable "n8n_desired_count" {
  description = "Desired number of N8N tasks"
  type        = number
  default     = 1
}

# Service Discovery
variable "service_discovery_redis_arn" {
  description = "Service discovery ARN for Redis"
  type        = string
  default     = ""
}

# Database Configuration
variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

# Redis Configuration (optional - for Redis container if needed)
variable "redis_cpu" {
  description = "CPU units for Redis container"
  type        = number
  default     = 256
}

variable "redis_memory" {
  description = "Memory (MB) for Redis container"
  type        = number
  default     = 512
}

variable "redis_image" {
  description = "Redis Docker image"
  type        = string
  default     = "redis:6-alpine"
}

variable "n8n_image" {
  description = "N8N Docker image"
  type        = string
  default     = "n8nio/n8n:latest"
}

variable "n8n_worker_cpu" {
  description = "CPU units for N8N worker container"
  type        = number
  default     = 256
}

variable "n8n_worker_memory" {
  description = "Memory (MB) for N8N worker container"
  type        = number
  default     = 512
}