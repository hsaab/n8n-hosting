# ---------------------------------------------------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# This replaces port mapping from docker-compose and provides a public endpoint for n8n
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "n8n" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets           = aws_subnet.public[*].id

  enable_deletion_protection = false
  enable_http2              = true
  enable_cross_zone_load_balancing = true
}

# ---------------------------------------------------------------------------------------------------------------------
# TARGET GROUP
# This defines where the ALB routes traffic to (our n8n ECS service)
# Note: target_type is "instance" for EC2 (vs "ip" for Fargate)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "n8n" {
  name        = "${var.cluster_name}-tg"
  port        = 5678
  protocol    = "HTTP"
  vpc_id      = aws_vpc.n8n.id
  target_type = "instance"  # Changed from "ip" for EC2

  health_check {
    enabled             = true
    interval            = 30
    path                = "/healthz"  # n8n health check endpoint
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  # Sticky sessions - important for n8n
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  deregistration_delay = 30
}

# ---------------------------------------------------------------------------------------------------------------------
# ALB LISTENERS
# These define how the ALB handles incoming requests
# ---------------------------------------------------------------------------------------------------------------------

# HTTP Listener - redirects to HTTPS if certificate is provided
resource "aws_lb_listener" "n8n" {
  load_balancer_arn = aws_lb.n8n.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"
    
    # If certificate exists, redirect HTTP to HTTPS
    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    
    # If no certificate, forward to target group
    target_group_arn = var.certificate_arn == "" ? aws_lb_target_group.n8n.arn : null
  }
}

# HTTPS Listener - only created if certificate is provided
resource "aws_lb_listener" "n8n_https" {
  count = var.certificate_arn != "" ? 1 : 0
  
  load_balancer_arn = aws_lb.n8n.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.n8n.arn
  }
}