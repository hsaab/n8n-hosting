# ---------------------------------------------------------------------------------------------------------------------
# ECS CLUSTER
# This is just a logical grouping - doesn't create any actual infrastructure
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_cluster" "n8n" {
  name = var.cluster_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ECS TASK DEFINITIONS
# These are like docker-compose service definitions - they specify container configurations
# ---------------------------------------------------------------------------------------------------------------------

# Redis removed - using RDS PostgreSQL for data persistence

# ---------------------------------------------------------------------------------------------------------------------
# N8N MAIN TASK DEFINITION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "n8n" {
  family                   = "${var.cluster_name}-n8n"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.n8n_cpu
  memory                   = var.n8n_memory
  # Force new revision
  tags = {
    Version = "v6"
  }
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "n8n"
      image     = var.n8n_image
      essential = true
      
      # Run as user 1000
      user = "1000"
      
      portMappings = [
        {
          containerPort = 5678
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
          value = var.rds_endpoint  # RDS endpoint
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
          value = "redis.n8n.local"  # Service discovery hostname
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
          value = "debug"
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

      # Mount EFS for persistent storage
      mountPoints = [
        {
          sourceVolume  = "n8n-storage"
          containerPath = "/data"
        }
      ]

      # Remove user constraint to run as root, then create directories with proper ownership
      # user = "1000"

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.n8n.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
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
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.n8n_worker_cpu
  memory                   = var.n8n_worker_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn           = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "n8n-worker"
      image     = var.n8n_image
      essential = true
      
      # Run as user 1000
      user = "1000"

      # Same environment as main n8n
      environment = [
        {
          name  = "DB_TYPE"
          value = "postgresdb"
        },
        {
          name  = "DB_POSTGRESDB_HOST"
          value = var.rds_endpoint  # RDS endpoint
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
          value = "redis.n8n.local"
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
          value = "debug"
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

      mountPoints = [
        {
          sourceVolume  = "n8n-storage"
          containerPath = "/data"
        }
      ]

      # Remove user constraint to run as root, then create directories with proper ownership
      # user = "1000"

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

# Redis service removed - using RDS PostgreSQL instead

# N8N Main Service
resource "aws_ecs_service" "n8n" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.n8n.id
  task_definition = aws_ecs_task_definition.n8n.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.n8n_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "n8n"
    container_port   = 5678
  }

  # Dependencies managed by module orchestration
}

# N8N Worker Service
resource "aws_ecs_service" "n8n_worker" {
  name            = "${var.service_name}-worker"
  cluster         = aws_ecs_cluster.n8n.id
  task_definition = aws_ecs_task_definition.n8n_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.n8n_security_group_id]
    assign_public_ip = true
  }

  depends_on = [
    aws_ecs_service.n8n,
    # RDS dependency managed by module orchestration
  ]
}