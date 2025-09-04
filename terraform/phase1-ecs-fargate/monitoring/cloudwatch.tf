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
# CLOUDWATCH DASHBOARD
# Monitor N8N performance and health
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "n8n" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "ALB Metrics"
          period  = 300
        }
      }
    ]
  })
}