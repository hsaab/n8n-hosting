# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AWS PROVIDER
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES FOR EXISTING INFRASTRUCTURE
# Reference your existing VPC and subnets
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS CLUSTER
# This is just a logical grouping - doesn't create any actual infrastructure
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster" "n8n" {
  name = var.cluster_name
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUPS
# For container logs - similar to docker logs
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "n8n" {
  name              = "/ecs/${var.cluster_name}/n8n"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "n8n_worker" {
  name              = "/ecs/${var.cluster_name}/n8n-worker"
  retention_in_days = 1
}


resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.cluster_name}/redis"
  retention_in_days = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR ECS TASK EXECUTION
# This role is used by ECS to pull images and write logs
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "${var.cluster_name}-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.n8n_secrets.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR ECS TASKS
# This role is used by the containers themselves
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# Control network access between containers and from ALB
# ---------------------------------------------------------------------------------------------------------------------

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for n8n ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-ecs-tasks-sg"
  description = "Security group for n8n ECS tasks"
  vpc_id      = var.vpc_id

  # Allow inbound from ALB
  ingress {
    description     = "Allow inbound from ALB"
    from_port       = 5678
    to_port         = 5678
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow containers to communicate with each other
  ingress {
    description = "Allow containers to communicate"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for Redis
resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EFS FOR PERSISTENT STORAGE
# Replaces Docker volumes from docker-compose
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_file_system" "n8n_storage" {
  creation_token = "${var.cluster_name}-n8n-storage"
  encrypted      = true

  tags = {
    Name = "${var.cluster_name}-n8n-storage"
  }
}

resource "aws_efs_mount_target" "n8n_storage" {
  count          = length(var.private_subnet_ids)
  file_system_id = aws_efs_file_system.n8n_storage.id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE DISCOVERY
# This replaces Docker's internal DNS (postgres, redis hostnames in docker-compose)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "n8n" {
  name        = "n8n.local"
  description = "Private DNS namespace for n8n services"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "redis" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.n8n.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}