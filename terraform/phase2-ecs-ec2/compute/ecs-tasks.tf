# ---------------------------------------------------------------------------------------------------------------------
# ECS TASK DEFINITIONS
# These are like docker-compose service definitions - they specify container configurations
# Note: For EC2, we use "bridge" network mode and dynamic port mapping
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# N8N MAIN TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n" {
  family                   = "${var.cluster_name}-n8n"
  network_mode             = "bridge"  # Changed from awsvpc for EC2
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "n8n"
      image     = "n8nio/n8n:${var.n8n_image_tag}"
      essential = true
      
      # Memory and CPU limits
      memory = var.n8n_memory
      cpu    = var.n8n_cpu
      
      # Run as user 1000
      user = "1000"
      
      portMappings = [
        {
          containerPort = 5678
          hostPort      = 0  # Dynamic port mapping for EC2
          protocol      = "tcp"
        }
      ]

      # Environment variables matching docker-compose
      environment = [
        {
          name  = "DB_TYPE"
          value = "postgresdb"
        },
        {
          name  = "DB_POSTGRESDB_HOST"
          value = var.rds_endpoint
        },
        {
          name  = "DB_POSTGRESDB_PORT"
          value = "5432"
        },
        {
          name  = "EXECUTIONS_MODE"
          value = "queue"
        },
        {
          name  = "QUEUE_BULL_REDIS_HOST"
          value = var.redis_endpoint
        },
        {
          name  = "QUEUE_BULL_REDIS_PORT"
          value = "6379"
        },
        {
          name  = "QUEUE_HEALTH_CHECK_ACTIVE"
          value = "true"
        },
        {
          name  = "DB_POSTGRESDB_SSL_MODE"
          value = "disable"
        },
        {
          name  = "N8N_SECURE_COOKIE"
          value = "false"
        },
        {
          name  = "N8N_LOG_LEVEL"
          value = "info"
        },
        {
          name  = "N8N_LOG_OUTPUT"
          value = "console"
        }
      ]

      # Secrets from Secrets Manager
      secrets = [
        {
          name      = "DB_POSTGRESDB_DATABASE"
          valueFrom = "${var.n8n_secrets_arn}:postgres_db::"
        },
        {
          name      = "DB_POSTGRESDB_USER"
          valueFrom = "${var.n8n_secrets_arn}:postgres_user::"
        },
        {
          name      = "DB_POSTGRESDB_PASSWORD"
          valueFrom = "${var.n8n_secrets_arn}:postgres_password::"
        },
        {
          name      = "N8N_ENCRYPTION_KEY"
          valueFrom = "${var.n8n_secrets_arn}:encryption_key::"
        }
      ]

# Redis auth secret (if configured) will be handled by conditional logic in secrets array above

      # Mount EFS for persistent storage
      mountPoints = [
        {
          sourceVolume  = "n8n-storage"
          containerPath = "/data"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5678/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  # EFS volume configuration with access point
  volume {
    name = "n8n-storage"

    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam            = "ENABLED"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# N8N WORKER TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n_worker" {
  family                   = "${var.cluster_name}-n8n-worker"
  network_mode             = "bridge"  # Changed from awsvpc for EC2
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "n8n-worker"
      image     = "n8nio/n8n:${var.n8n_image_tag}"
      essential = true
      
      # Memory and CPU limits
      memory = var.n8n_worker_memory
      cpu    = var.n8n_worker_cpu
      
      # Run as user 1000
      user = "1000"

      # Worker command
      command = ["worker"]

      # Same environment as main n8n
      environment = [
        {
          name  = "DB_TYPE"
          value = "postgresdb"
        },
        {
          name  = "DB_POSTGRESDB_HOST"
          value = var.rds_endpoint
        },
        {
          name  = "DB_POSTGRESDB_PORT"
          value = "5432"
        },
        {
          name  = "EXECUTIONS_MODE"
          value = "queue"
        },
        {
          name  = "QUEUE_BULL_REDIS_HOST"
          value = var.redis_endpoint
        },
        {
          name  = "QUEUE_BULL_REDIS_PORT"
          value = "6379"
        },
        {
          name  = "QUEUE_HEALTH_CHECK_ACTIVE"
          value = "true"
        },
        {
          name  = "DB_POSTGRESDB_SSL_MODE"
          value = "disable"
        },
        {
          name  = "N8N_LOG_LEVEL"
          value = "info"
        },
        {
          name  = "N8N_LOG_OUTPUT"
          value = "console"
        }
      ]

      secrets = [
        {
          name      = "DB_POSTGRESDB_DATABASE"
          valueFrom = "${var.n8n_secrets_arn}:postgres_db::"
        },
        {
          name      = "DB_POSTGRESDB_USER"
          valueFrom = "${var.n8n_secrets_arn}:postgres_user::"
        },
        {
          name      = "DB_POSTGRESDB_PASSWORD"
          valueFrom = "${var.n8n_secrets_arn}:postgres_password::"
        },
        {
          name      = "N8N_ENCRYPTION_KEY"
          valueFrom = "${var.n8n_secrets_arn}:encryption_key::"
        }
      ]

# Redis auth secret (if configured) will be handled by conditional logic in secrets array above

      mountPoints = [
        {
          sourceVolume  = "n8n-storage"
          containerPath = "/data"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n_worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  volume {
    name = "n8n-storage"

    efs_volume_configuration {
      file_system_id          = var.efs_file_system_id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam            = "ENABLED"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS SERVICES
# These manage running instances of our task definitions
# ---------------------------------------------------------------------------------------------------------------------

# N8N Main Service
resource "aws_ecs_service" "n8n" {
  name            = "${var.cluster_name}-n8n-service"
  cluster         = aws_ecs_cluster.n8n.id
  task_definition = aws_ecs_task_definition.n8n.arn
  desired_count   = 1

  # Use capacity provider instead of launch_type
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    base              = 1
    weight            = 100
  }

  # Deployment configuration
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "n8n"
    container_port   = 5678
  }

  # Placement constraints - spread across instances
  placement_constraints {
    type = "distinctInstance"
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.n8n
  ]
}

# N8N Worker Service
resource "aws_ecs_service" "n8n_worker" {
  name            = "${var.cluster_name}-n8n-worker-service"
  cluster         = aws_ecs_cluster.n8n.id
  task_definition = aws_ecs_task_definition.n8n_worker.arn
  desired_count   = 1

  # Use capacity provider instead of launch_type
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 100
  }

  # Deployment configuration
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  # Placement strategy - spread across instances
  placement_constraints {
    type = "distinctInstance"
  }

  depends_on = [
    aws_ecs_service.n8n,
    aws_ecs_cluster_capacity_providers.n8n
  ]
}