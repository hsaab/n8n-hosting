# ---------------------------------------------------------------------------------------------------------------------
# EXISTING INFRASTRUCTURE REFERENCES
# These variables reference your existing AWS infrastructure to minimize new resource creation
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of your existing VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of existing public subnet IDs for ALB"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
  default     = "n8n-cluster"
}

variable "service_name" {
  description = "Name for the ECS service"
  type        = string
  default     = "n8n-service"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONTAINER CONFIGURATION
# Based on your docker-compose.yml settings
# ---------------------------------------------------------------------------------------------------------------------

variable "n8n_image" {
  description = "N8N Docker image"
  type        = string
  default     = "docker.n8n.io/n8nio/n8n:latest"
}

variable "redis_image" {
  description = "Redis Docker image"
  type        = string
  default     = "redis:6-alpine"
}

# ---------------------------------------------------------------------------------------------------------------------
# RESOURCE SIZING
# Fargate requires specific CPU/Memory combinations
# CPU: 256 (.25 vCPU), 512 (.5 vCPU), 1024 (1 vCPU), 2048 (2 vCPU), 4096 (4 vCPU)
# Memory: Depends on CPU - see AWS documentation
# ---------------------------------------------------------------------------------------------------------------------

variable "n8n_cpu" {
  description = "CPU units for n8n main container (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "n8n_memory" {
  description = "Memory for n8n main container in MB"
  type        = number
  default     = 512
}

variable "n8n_worker_cpu" {
  description = "CPU units for n8n worker container"
  type        = number
  default     = 256
}

variable "n8n_worker_memory" {
  description = "Memory for n8n worker container in MB"
  type        = number
  default     = 512
}

variable "redis_cpu" {
  description = "CPU units for Redis container"
  type        = number
  default     = 256
}

variable "redis_memory" {
  description = "Memory for Redis container in MB"
  type        = number
  default     = 512
}

# ---------------------------------------------------------------------------------------------------------------------
# RDS POSTGRESQL CONFIGURATION
# Managed database configuration replacing containerized PostgreSQL
# ---------------------------------------------------------------------------------------------------------------------

variable "rds_engine_version" {
  description = "PostgreSQL engine version for RDS"
  type        = string
  default     = "16.4"
}

variable "rds_instance_class" {
  description = "RDS instance class (e.g., db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Daily backup window for RDS (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Weekly maintenance window for RDS (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_performance_insights_enabled" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot when deleting RDS"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABASE CREDENTIALS
# These match your .env file settings
# ---------------------------------------------------------------------------------------------------------------------

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n"
}

variable "postgres_user" {
  description = "PostgreSQL root username"
  type        = string
  default     = "root_user"
}

variable "postgres_password" {
  description = "PostgreSQL root password"
  type        = string
  sensitive   = true
}

variable "postgres_non_root_user" {
  description = "PostgreSQL non-root username for n8n"
  type        = string
  default     = "n8n_user"
}

variable "postgres_non_root_password" {
  description = "PostgreSQL non-root password"
  type        = string
  sensitive   = true
}

variable "encryption_key" {
  description = "N8N encryption key for securing credentials"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------------------------------------------------
# LOAD BALANCER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (optional)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for n8n (optional)"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# TAGS
# ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "learning"
    ManagedBy   = "terraform"
    Application = "n8n"
  }
}