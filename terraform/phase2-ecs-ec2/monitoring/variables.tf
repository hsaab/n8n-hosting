# =============================================================================
# MONITORING MODULE VARIABLES
# =============================================================================

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Dependencies for monitoring
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  type        = string
}

variable "rds_db_instance_identifier" {
  description = "RDS database instance identifier"
  type        = string
}

variable "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}