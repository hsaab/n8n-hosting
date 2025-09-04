#!/bin/bash
# Log everything for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting ECS configuration..."

# Update packages first
yum update -y

# Configure ECS agent BEFORE starting services
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config

# Enable CloudWatch Container Insights
if [ "${enable_container_insights}" = "true" ]; then
  echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config
fi

# Install additional packages
yum install -y amazon-cloudwatch-agent htop aws-cli jq

# Ensure Docker is running and will restart on boot
systemctl enable docker
systemctl start docker

# Wait for Docker to be fully ready
while ! systemctl is-active --quiet docker; do
  echo "Waiting for Docker to start..."
  sleep 2
done

echo "Docker is active, starting ECS agent..."

# Enable and start ECS service
systemctl enable ecs
systemctl start ecs

# Wait and verify ECS agent started
sleep 15

# Check ECS agent status
if systemctl is-active --quiet ecs; then
  echo "ECS agent is running successfully"
else
  echo "ECS agent failed to start, trying again..."
  systemctl restart ecs
  sleep 10
fi

# Final status check
systemctl status ecs --no-pager -l
echo "ECS configuration complete"

# Show final cluster config for debugging
echo "Final ECS config:"
cat /etc/ecs/ecs.config
