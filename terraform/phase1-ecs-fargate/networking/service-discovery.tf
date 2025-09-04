# ---------------------------------------------------------------------------------------------------------------------
# SERVICE DISCOVERY
# This replaces Docker's internal DNS (postgres, redis hostnames in docker-compose)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "n8n" {
  name        = "n8n.local"
  description = "Private DNS namespace for n8n services"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "n8n" {
  name = "n8n"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.n8n.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}