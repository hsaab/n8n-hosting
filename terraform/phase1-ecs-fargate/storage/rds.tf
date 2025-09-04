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

# Parameter group to allow non-SSL connections
resource "aws_db_parameter_group" "n8n_postgres" {
  family = "postgres16"
  name   = "${var.cluster_name}-postgres-params"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name = "${var.cluster_name} PostgreSQL Parameter Group"
  }
}

# RDS security group is managed by the security module

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
  vpc_security_group_ids = [var.rds_security_group_id]
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
  
  # Disable SSL requirement for initial setup
  parameter_group_name = aws_db_parameter_group.n8n_postgres.name
  
  tags = {
    Name = "${var.cluster_name} PostgreSQL Database"
  }
}

# RDS endpoint is provided via module outputs