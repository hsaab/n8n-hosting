# =============================================================================
# CLOUDWATCH LOG GROUPS FOR COMPUTE MODULE
# =============================================================================

resource "aws_cloudwatch_log_group" "n8n" {
  name              = "/ecs/${var.cluster_name}/n8n"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.cluster_name}-n8n-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "n8n_worker" {
  name              = "/ecs/${var.cluster_name}/n8n-worker"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.cluster_name}-n8n-worker-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/${var.cluster_name}/redis"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.cluster_name}-redis-logs"
    Environment = var.environment
  }
}