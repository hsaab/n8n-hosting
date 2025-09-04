# ---------------------------------------------------------------------------------------------------------------------
# SERVICE DISCOVERY
# This replaces Docker's internal DNS (postgres, redis hostnames in docker-compose)
# Allows containers to discover each other using DNS names
# ---------------------------------------------------------------------------------------------------------------------

# Private DNS namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "n8n" {
  name        = "n8n.local"
  description = "Private DNS namespace for n8n services"
  vpc         = aws_vpc.n8n.id

  tags = {
    Name = "${var.cluster_name}-service-discovery"
  }
}

# Service discovery for n8n main application
resource "aws_service_discovery_service" "n8n" {
  name = "n8n"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.n8n.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service discovery for n8n worker
resource "aws_service_discovery_service" "n8n_worker" {
  name = "n8n-worker"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.n8n.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Note: PostgreSQL and Redis service discovery resources
# are created in their respective storage modules