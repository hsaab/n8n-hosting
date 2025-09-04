# ---------------------------------------------------------------------------------------------------------------------
# AWS SECRETS MANAGER
# Securely stores sensitive configuration instead of using .env file
# ---------------------------------------------------------------------------------------------------------------------

# Create the secret
resource "aws_secretsmanager_secret" "n8n_secrets" {
  name                    = "${var.cluster_name}-secrets"
  description             = "Secrets for n8n ECS deployment on EC2"
  recovery_window_in_days = 7  # Keep deleted secrets for 7 days before permanent deletion

  tags = {
    Name = "${var.cluster_name}-secrets"
  }
}

# Secret values - these replace your .env file
resource "aws_secretsmanager_secret_version" "n8n_secrets" {
  secret_id = aws_secretsmanager_secret.n8n_secrets.id

  secret_string = jsonencode({
    postgres_db       = var.postgres_db
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
    encryption_key    = var.n8n_encryption_key
    redis_auth_token  = var.redis_password
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM POLICY FOR EC2 INSTANCES TO ACCESS SECRETS
# Allow EC2 instances to retrieve secrets for containers
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ec2_secrets_access" {
  name = "${var.cluster_name}-ec2-secrets-policy"
  role = aws_iam_role.ec2_instance.id

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