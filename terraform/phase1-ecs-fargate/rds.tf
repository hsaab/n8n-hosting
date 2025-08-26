# ---------------------------------------------------------------------------------------------------------------------
# RDS POSTGRESQL DATABASE
# Managed PostgreSQL database replacing the containerized version
# ---------------------------------------------------------------------------------------------------------------------

# Subnet group for RDS
resource "aws_db_subnet_group" "n8n" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.cluster_name} DB subnet group"
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
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

# RDS PostgreSQL instance
resource "aws_db_instance" "n8n" {
  identifier = "${var.cluster_name}-postgres"
  
  # Engine configuration
  engine               = "postgres"
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  
  # Storage configuration
  allocated_storage     = var.rds_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  
  # Database configuration
  db_name  = var.postgres_db
  username = var.postgres_user
  password = var.postgres_password
  port     = 5432
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.n8n.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  
  # Backup configuration
  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window
  
  # High availability
  multi_az = var.rds_multi_az
  
  # Performance Insights
  performance_insights_enabled = var.rds_performance_insights_enabled
  performance_insights_retention_period = var.rds_performance_insights_enabled ? 7 : null
  
  # Other settings
  auto_minor_version_upgrade = true
  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot      = var.rds_skip_final_snapshot
  final_snapshot_identifier = var.rds_skip_final_snapshot ? null : "${var.cluster_name}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  tags = {
    Name = "${var.cluster_name} PostgreSQL Database"
  }
}

# Store RDS endpoint in Secrets Manager for easy access
resource "aws_secretsmanager_secret_version" "rds_endpoint" {
  secret_id = aws_secretsmanager_secret.n8n_secrets.id
  secret_string = jsonencode(merge(
    jsondecode(aws_secretsmanager_secret_version.n8n_secrets.secret_string),
    {
      rds_endpoint = aws_db_instance.n8n.endpoint
      rds_address  = aws_db_instance.n8n.address
    }
  ))
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}