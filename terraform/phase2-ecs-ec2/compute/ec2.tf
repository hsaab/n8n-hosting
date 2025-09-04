# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

# Get the latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LAUNCH TEMPLATE FOR EC2 INSTANCES
# Defines the configuration for EC2 instances in the Auto Scaling Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  # IAM instance profile
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  # Security groups
  vpc_security_group_ids = [var.ecs_instance_security_group_id]

  # Key pair for SSH access (optional)
  key_name = var.key_name != "" ? var.key_name : null

  # EBS optimization
  ebs_optimized = true

  # Root block device
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted            = true
      delete_on_termination = true
    }
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  # User data script to join ECS cluster
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    region       = var.aws_region
    enable_container_insights = var.enable_container_insights
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-ecs-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-ecs-volume"
      }
    )
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTO SCALING GROUP
# Manages EC2 instances for the ECS cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "ecs_instances" {
  name                = "${var.cluster_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Health checks
  health_check_type         = "EC2"
  health_check_grace_period = 300
  default_cooldown         = 300

  # Instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Launch template configuration for On-Demand instances only
  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }

  # Protect from scale-in during deployments
  protect_from_scale_in = false

  # Tags
  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AUTO SCALING POLICIES
# Define when to scale out or scale in
# ---------------------------------------------------------------------------------------------------------------------

# Scale out policy
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.cluster_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.ecs_instances.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown              = var.scale_out_cooldown
}

# Scale in policy
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.cluster_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.ecs_instances.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown              = var.scale_in_cooldown
}

# ---------------------------------------------------------------------------------------------------------------------
# USER DATA SCRIPT
# Create the user data script file
# ---------------------------------------------------------------------------------------------------------------------

