# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# Control network access between containers, EC2 instances, and from ALB
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

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Security group for EC2 instances in ECS cluster
resource "aws_security_group" "ec2_instances" {
  name        = "${var.cluster_name}-ec2-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = var.vpc_id

  # Allow inbound from ALB for dynamic port mapping
  ingress {
    description     = "Allow dynamic ports from ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow containers on same instances to communicate
  ingress {
    description = "Allow containers to communicate"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # SSH access (optional, remove in production)
  dynamic "ingress" {
    for_each = var.enable_ssh ? [1] : []
    content {
      description = "SSH from allowed IPs"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_ips
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-ec2-sg"
  }
}

# Security group for ECS tasks (containers)
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

  # Allow EC2 instances to communicate with containers
  ingress {
    description     = "Allow from EC2 instances"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instances.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-ecs-tasks-sg"
  }
}

# Security group for RDS database
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Allow PostgreSQL access from ECS tasks
  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow PostgreSQL access from EC2 instances (for troubleshooting)
  ingress {
    description     = "PostgreSQL from EC2 instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instances.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# Security group for ElastiCache Redis
resource "aws_security_group" "redis" {
  name        = "${var.cluster_name}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  # Allow Redis access from ECS tasks
  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Allow Redis access from EC2 instances (for troubleshooting)
  ingress {
    description     = "Redis from EC2 instances"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instances.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-redis-sg"
  }
}

# Security group for EFS mount targets
resource "aws_security_group" "efs" {
  name        = "${var.cluster_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  # Allow NFS access from EC2 instances
  ingress {
    description     = "NFS from EC2 instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instances.id]
  }

  # Allow NFS access from ECS tasks (if using Fargate with EFS)
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

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }
}