# =============================================================================
# ROOT LEVEL VARIABLES
# =============================================================================
# These variables are passed down to individual modules

# Core Configuration
variable "cluster_name" {
  description = "Name of the ECS cluster and resource prefix"
  type        = string
  default     = "n8n-ec2-phase2"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "prod"
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS (leave empty for HTTP only)"
  type        = string
  default     = ""
}

# =============================================================================
# N8N APPLICATION CONFIGURATION  
# =============================================================================
variable "n8n_encryption_key" {
  description = "Encryption key for n8n (generate with: openssl rand -base64 32)"
  type        = string
  sensitive   = true
}

# Legacy variable name from terraform.tfvars - maps to n8n_encryption_key
variable "encryption_key" {
  description = "Legacy variable name - use n8n_encryption_key instead"
  type        = string
  default     = ""
  sensitive   = true
}

variable "n8n_image_tag" {
  description = "N8N Docker image tag"
  type        = string
  default     = "latest"
}

variable "n8n_cpu" {
  description = "CPU units for N8N container (1024 = 1 vCPU)"
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

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "n8n"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "n8n"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

# RDS Configuration
variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "rds_backup_retention_period" {
  description = "Backup retention period (days)"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "rds_performance_insights_enabled" {
  description = "Enable RDS Performance Insights"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for RDS instance"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot when destroying RDS instance"
  type        = bool
  default     = true
}

# =============================================================================
# REDIS CONFIGURATION
# =============================================================================
variable "redis_password" {
  description = "Redis password/auth token"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

# =============================================================================
# EC2 CONFIGURATION
# =============================================================================
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in auto scaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances in auto scaling group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in auto scaling group"
  type        = number
  default     = 1
}

variable "enable_container_insights" {
  description = "Enable Container Insights for ECS cluster"
  type        = bool
  default     = false
}

variable "target_capacity" {
  description = "Target capacity percentage for ECS cluster capacity provider"
  type        = number
  default     = 100
}

# =============================================================================
# LEGACY VARIABLES FROM TERRAFORM.TFVARS
# These provide backward compatibility with existing tfvars files
# =============================================================================

variable "vpc_id" {
  description = "Existing VPC ID (legacy - not used in module structure)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs (legacy - not used in module structure)"  
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs (legacy - not used in module structure)"
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "ECS service name (legacy)"
  type        = string
  default     = ""
}

variable "postgres_non_root_user" {
  description = "PostgreSQL non-root username (legacy)"
  type        = string
  default     = ""
}

variable "postgres_non_root_password" {
  description = "PostgreSQL non-root password (legacy)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_parameter_group" {
  description = "Redis parameter group name (legacy)"
  type        = string
  default     = "default.redis7"
}

variable "redis_transit_encryption" {
  description = "Enable Redis transit encryption (legacy)"
  type        = bool
  default     = false
}

variable "redis_auth_token" {
  description = "Redis auth token (legacy - use redis_password instead)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "redis_maintenance_window" {
  description = "Redis maintenance window (legacy)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "redis_snapshot_retention" {
  description = "Redis snapshot retention days (legacy)"
  type        = number
  default     = 1
}

variable "redis_snapshot_window" {
  description = "Redis snapshot window (legacy)"
  type        = string
  default     = "02:00-03:00"
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis cache clusters (legacy)"
  type        = number
  default     = 1
}