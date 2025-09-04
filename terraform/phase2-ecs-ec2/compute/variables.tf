# =============================================================================
# COMPUTE MODULE VARIABLES
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
variable "ecs_instance_security_group_id" {
  description = "Security group ID for ECS instances"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
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

variable "rds_endpoint" {
  description = "RDS instance endpoint"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 1
}

variable "enable_container_insights" {
  description = "Enable Container Insights for ECS cluster"
  type        = bool
  default     = false
}

variable "target_capacity" {
  description = "Target capacity for the ECS cluster"
  type        = number
  default     = 100
}

# N8N Configuration
variable "n8n_image_tag" {
  description = "N8N Docker image tag"
  type        = string
  default     = "1.63.4"
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

# Database Configuration
variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

# Optional SSH Configuration
variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}


# EFS Access Point
variable "efs_access_point_id" {
  description = "EFS access point ID"
  type        = string
}

# Auto Scaling Configuration
variable "scale_out_cooldown" {
  description = "Cooldown period for scale out actions (seconds)"
  type        = number
  default     = 300
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale in actions (seconds)"
  type        = number
  default     = 300
}