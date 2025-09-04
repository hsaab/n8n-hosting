# =============================================================================
# CLOUDWATCH LOG GROUPS FOR ECS TASKS
# =============================================================================

resource "aws_cloudwatch_log_group" "n8n" {
  name              = "/ecs/${var.cluster_name}/n8n"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-n8n-logs"
  })
}

resource "aws_cloudwatch_log_group" "n8n_worker" {
  name              = "/ecs/${var.cluster_name}/n8n-worker"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-n8n-worker-logs"
  })
}