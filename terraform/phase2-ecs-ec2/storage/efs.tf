# ---------------------------------------------------------------------------------------------------------------------
# EFS FOR PERSISTENT STORAGE
# Replaces Docker volumes from docker-compose
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_file_system" "n8n_storage" {
  creation_token = "${var.cluster_name}-n8n-storage"
  encrypted      = true

  # Performance mode
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Lifecycle policy to save costs
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.cluster_name}-n8n-storage"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EFS ACCESS POINTS
# Provide application-specific entry points to the file system
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_access_point" "n8n_data" {
  file_system_id = aws_efs_file_system.n8n_storage.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/n8n-data"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 755
    }
  }

  tags = {
    Name = "${var.cluster_name}-n8n-access-point"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EFS MOUNT TARGETS
# Create mount targets in each private subnet
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_mount_target" "n8n_storage" {
  count          = length(var.private_subnet_ids)
  file_system_id = aws_efs_file_system.n8n_storage.id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}


# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARMS FOR EFS
# Monitor EFS performance and availability
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  alarm_name          = "${var.cluster_name}-efs-burst-credit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000000"  # 1 TB in bytes
  alarm_description   = "EFS burst credit balance is low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = aws_efs_file_system.n8n_storage.id
  }
}

resource "aws_cloudwatch_metric_alarm" "efs_percent_io_limit" {
  alarm_name          = "${var.cluster_name}-efs-io-limit-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PercentIOLimit"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "EFS is approaching IO limit"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = aws_efs_file_system.n8n_storage.id
  }
}