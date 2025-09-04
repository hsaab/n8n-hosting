# =============================================================================
# SECURITY MODULE VARIABLES
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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# N8N Configuration
variable "n8n_encryption_key" {
  description = "Encryption key for n8n"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

# EFS Access Point for IAM policies
variable "efs_access_point_arn" {
  description = "ARN of the EFS access point"
  type        = string
  default     = ""
}