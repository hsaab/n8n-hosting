# ---------------------------------------------------------------------------------------------------------------------
# ECS CLUSTER
# The logical grouping of tasks and services
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster" "n8n" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS CAPACITY PROVIDER
# Links the Auto Scaling Group to the ECS cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.cluster_name}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_instances.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
      
      # Instance warmup period
      instance_warmup_period = 300
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER CAPACITY PROVIDER ASSOCIATION
# Associates the capacity provider with the cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster_capacity_providers" "n8n" {
  cluster_name = aws_ecs_cluster.n8n.name

  capacity_providers = [
    aws_ecs_capacity_provider.ec2.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    base              = 1
    weight            = 100
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUDWATCH ALARMS FOR CLUSTER MONITORING
# Monitor cluster health and capacity
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cluster_cpu_high" {
  alarm_name          = "${var.cluster_name}-cluster-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors cluster CPU utilization"

  dimensions = {
    ClusterName = aws_ecs_cluster.n8n.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cluster_cpu_low" {
  alarm_name          = "${var.cluster_name}-cluster-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors cluster CPU utilization for scale-in"

  dimensions = {
    ClusterName = aws_ecs_cluster.n8n.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}

resource "aws_cloudwatch_metric_alarm" "cluster_memory_high" {
  alarm_name          = "${var.cluster_name}-cluster-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors cluster memory utilization"

  dimensions = {
    ClusterName = aws_ecs_cluster.n8n.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}