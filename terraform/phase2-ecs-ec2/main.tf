# =============================================================================
# MAIN TERRAFORM CONFIGURATION - MODULE ORCHESTRATION
# =============================================================================
# This file orchestrates all the modules and defines the relationships between them.
# Each module represents a logical grouping of resources:
# - networking: VPC, subnets, ALB, service discovery
# - security: IAM roles, security groups, secrets management
# - storage: RDS, ElastiCache, EFS
# - compute: ECS cluster, EC2 instances, auto-scaling
# - monitoring: CloudWatch dashboards and alarms
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# NETWORKING MODULE
# Sets up VPC, subnets, ALB, and service discovery
# =============================================================================
module "networking" {
  source = "./networking"
  
  # Core configuration
  cluster_name     = var.cluster_name
  aws_region       = var.aws_region
  environment      = var.environment
  
  # Network configuration
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  
  # ALB configuration
  certificate_arn = var.certificate_arn
  
  # Security group dependencies
  alb_security_group_id = module.security.alb_security_group_id
}

# =============================================================================
# SECURITY MODULE
# IAM roles, security groups, and secrets management
# =============================================================================
module "security" {
  source = "./security"
  
  # Core configuration
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  environment  = var.environment
  
  # VPC dependency
  vpc_id = module.networking.vpc_id
  
  # N8N configuration for secrets
  n8n_encryption_key = var.n8n_encryption_key != "" ? var.n8n_encryption_key : var.encryption_key
  postgres_db        = var.postgres_db
  postgres_user      = var.postgres_user
  postgres_password  = var.postgres_password
  redis_password     = var.redis_password != "" ? var.redis_password : (var.redis_auth_token != "" ? var.redis_auth_token : "default-redis-password")
}

# =============================================================================
# STORAGE MODULE
# RDS PostgreSQL, ElastiCache Redis, and EFS
# =============================================================================
module "storage" {
  source = "./storage"
  
  # Core configuration
  cluster_name = var.cluster_name
  environment  = var.environment
  
  # Network dependencies
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  
  # Security dependencies
  rds_security_group_id   = module.security.rds_security_group_id
  redis_security_group_id = module.security.redis_security_group_id
  efs_security_group_id   = module.security.efs_security_group_id
  n8n_secrets_arn         = module.security.n8n_secrets_arn
  
  # Database configuration
  postgres_db       = var.postgres_db
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
  
  # RDS configuration
  rds_engine_version                    = var.rds_engine_version
  rds_instance_class                   = var.rds_instance_class
  rds_allocated_storage               = var.rds_allocated_storage
  rds_backup_retention_period         = var.rds_backup_retention_period
  rds_backup_window                   = var.rds_backup_window
  rds_maintenance_window              = var.rds_maintenance_window
  rds_multi_az                        = var.rds_multi_az
  rds_performance_insights_enabled    = var.rds_performance_insights_enabled
  rds_deletion_protection             = var.rds_deletion_protection
  rds_skip_final_snapshot             = var.rds_skip_final_snapshot
  
  # Redis configuration
  redis_password         = var.redis_password
  redis_node_type        = var.redis_node_type
  redis_num_cache_nodes  = var.redis_num_cache_nodes
  redis_engine_version   = var.redis_engine_version
}

# =============================================================================
# COMPUTE MODULE
# ECS cluster, EC2 instances, auto-scaling, and N8N service
# =============================================================================
module "compute" {
  source = "./compute"
  
  # Core configuration
  cluster_name = var.cluster_name
  aws_region   = var.aws_region
  environment  = var.environment
  
  # Network dependencies
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_target_group_arn  = module.networking.alb_target_group_arn
  
  # Security dependencies
  ecs_instance_security_group_id = module.security.ecs_instance_security_group_id
  ec2_instance_profile_name      = module.security.ec2_instance_profile_name
  ecs_task_execution_role_arn    = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn             = module.security.ecs_task_role_arn
  n8n_secrets_arn               = module.security.n8n_secrets_arn
  
  # Storage dependencies
  efs_file_system_id   = module.storage.efs_file_system_id
  efs_access_point_id  = module.storage.efs_access_point_id
  rds_endpoint         = module.storage.rds_endpoint
  redis_endpoint       = module.storage.redis_endpoint
  
  # EC2 configuration
  instance_type                = var.instance_type
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_capacity            = var.desired_capacity
  enable_container_insights   = var.enable_container_insights
  target_capacity             = var.target_capacity
  
  # N8N configuration
  n8n_image_tag    = var.n8n_image_tag
  n8n_cpu          = var.n8n_cpu
  n8n_memory       = var.n8n_memory
  n8n_desired_count = var.n8n_desired_count
  
  # Database configuration for connection string
  postgres_db   = var.postgres_db
  postgres_user = var.postgres_user
}

# =============================================================================
# MONITORING MODULE
# CloudWatch dashboards and custom alarms
# =============================================================================
module "monitoring" {
  source = "./monitoring"
  
  # Core configuration
  cluster_name = var.cluster_name
  environment  = var.environment
  aws_region   = var.aws_region
  
  # Dependencies for monitoring
  ecs_cluster_name     = module.compute.ecs_cluster_name
  alb_arn_suffix       = module.networking.alb_arn_suffix
  target_group_arn_suffix = module.networking.target_group_arn_suffix
  rds_db_instance_identifier = module.storage.rds_db_instance_identifier
  redis_cluster_id     = module.storage.redis_cluster_id
  
  # Auto Scaling Group for monitoring
  autoscaling_group_name = module.compute.autoscaling_group_name
}