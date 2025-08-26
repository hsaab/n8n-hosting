# ---------------------------------------------------------------------------------------------------------------------
# AWS SECRETS MANAGER
# Securely stores sensitive configuration instead of using .env file
# ---------------------------------------------------------------------------------------------------------------------

# Create the secret
resource "aws_secretsmanager_secret" "n8n_secrets" {
  name                    = "${var.cluster_name}-secrets"
  description             = "Secrets for n8n ECS deployment"
  recovery_window_in_days = 7  # Keep deleted secrets for 7 days before permanent deletion

  tags = {
    Name = "${var.cluster_name}-secrets"
  }
}

# Secret values - these replace your .env file
resource "aws_secretsmanager_secret_version" "n8n_secrets" {
  secret_id = aws_secretsmanager_secret.n8n_secrets.id

  secret_string = jsonencode({
    postgres_db                = var.postgres_db
    postgres_user              = var.postgres_user
    postgres_password          = var.postgres_password
    postgres_non_root_user     = var.postgres_non_root_user
    postgres_non_root_password = var.postgres_non_root_password
    encryption_key             = var.encryption_key
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS FOR SECRETS
# ---------------------------------------------------------------------------------------------------------------------

output "secrets_arn" {
  description = "ARN of the secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.n8n_secrets.arn
  sensitive   = true
}

output "secrets_name" {
  description = "Name of the secrets in Secrets Manager"
  value       = aws_secretsmanager_secret.n8n_secrets.name
}