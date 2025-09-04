# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR ECS TASK EXECUTION
# This role is used by ECS to pull images and write logs
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.cluster_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "${var.cluster_name}-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.n8n_secrets.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE FOR ECS TASKS
# This role is used by the containers themselves
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name = "${var.cluster_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# EFS access policy for task role
resource "aws_iam_role_policy" "ecs_task_efs" {
  name = "${var.cluster_name}-task-efs-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:AccessPointExists",
          "elasticfilesystem:AccessPoint",
          "elasticfilesystem:PutFileSystemPolicy",
          "elasticfilesystem:GetFileSystemPolicy",
          "elasticfilesystem:DeleteFileSystemPolicy",
        ]
        Resource = var.efs_access_point_arn != "" ? var.efs_access_point_arn : "*"
      }
    ]
  })
}