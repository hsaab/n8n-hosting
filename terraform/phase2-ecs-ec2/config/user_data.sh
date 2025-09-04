#!/bin/bash
# Log everything for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting ECS configuration..."

# Update packages first
yum update -y

# Configure ECS agent
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

# Make sure Docker is running
systemctl start docker
systemctl enable docker

# Start and enable ECS agent
systemctl start ecs
systemctl enable ecs

# Wait a bit for the agent to start
sleep 10

# Check status
systemctl status ecs --no-pager
echo "ECS configuration complete"