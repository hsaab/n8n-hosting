# N8N ECS EC2 Deployment - Troubleshooting Guide

This guide documents common issues encountered when deploying n8n on AWS ECS with EC2 launch type and their detailed solutions.

## Table of Contents
1. [Missing User Data Script](#1-missing-user-data-script)
2. [ECS Agent Not Starting](#2-ecs-agent-not-starting)  
3. [Docker Hub Authentication Issues](#3-docker-hub-authentication-issues)
4. [Container Exit Code 1 Issues](#4-container-exit-code-1-issues)
5. [Network Connectivity Problems](#5-network-connectivity-problems)

---

## 1. Missing User Data Script

### **Problem**
Terraform deployment fails with error:
```
Error: Invalid function argument
no file exists at compute/user_data.sh
```

### **Root Cause**
The EC2 launch template references a user_data.sh file that doesn't exist in the compute directory.

### **Symptoms**
- Terraform validation fails
- Cannot deploy infrastructure
- Error specifically mentions missing user_data.sh file
- terraform plan/apply fails immediately

### **Solution**
Create the missing user_data.sh file with proper ECS configuration:

```bash
# Create the file at terraform/phase2-ecs-ec2/compute/user_data.sh
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
```

### **Why This Works**
- Creates the missing file that terraform references
- Properly configures ECS agent to join the cluster
- Includes robust error handling and logging
- Ensures Docker starts before ECS agent

---

## 2. ECS Agent Not Starting

### **Problem**
EC2 instances launch successfully but ECS agent fails to start, preventing container instances from registering with the cluster.

### **Root Cause Analysis**
Multiple potential issues:

#### **Issue A: Conflicting User Data Scripts**
Two user_data scripts exist and conflict:
- `compute/user_data.sh` (used by launch template)
- `compute/ec2.tf` local_file resource (overwrites the first)

#### **Issue B: ECS Service Hangs During Startup**
The `systemctl start ecs` command hangs indefinitely, preventing script completion.

### **Symptoms**
- EC2 instances running but not registered in ECS cluster
- `aws ecs list-container-instances --cluster cluster-name` returns empty
- ECS tasks stuck in PENDING state
- 503 errors from load balancer (no healthy targets)

### **Deep Dive Analysis**

**Cluster Status Check:**
```bash
aws ecs describe-clusters --clusters n8n-ec2-phase2 --query 'clusters[0].{registeredInstances:registeredContainerInstancesCount,runningTasks:runningTasksCount,pendingTasks:pendingTasksCount}'
# Expected: registeredInstances > 0
# Actual: registeredInstances = 0
```

**Instance Investigation:**
```bash
# Connect via AWS SSM
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["systemctl status ecs --no-pager"]'

# Results show: Active: inactive (dead)
```

### **Solutions**

#### **Fix A: Remove Conflicting local_file Resource**
```hcl
# In compute/ec2.tf - REMOVE this entire block:
resource "local_file" "user_data" {
  content = <<-EOF
    #!/bin/bash
    # ... conflicting script
  EOF
  filename = "${path.module}/user_data.sh"
}
```

#### **Fix B: Manual ECS Agent Start**
If ECS agent still won't start automatically, start it manually:

```bash
# Connect to instance via SSM
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["/usr/libexec/amazon-ecs-init pre-start", "/usr/libexec/amazon-ecs-init start"]'
```

#### **Fix C: Add Missing Template Variables**
Ensure all variables are passed to the user_data template:

```hcl
# In compute/ec2.tf
user_data = base64encode(templatefile("${path.module}/user_data.sh", {
  cluster_name = var.cluster_name
  region       = var.aws_region
  enable_container_insights = var.enable_container_insights  # ← Add missing variable
}))
```

### **Verification Steps**
1. **Check ECS Agent Running:**
   ```bash
   docker ps | grep amazon-ecs-agent
   # Should show: amazon-ecs-agent:latest ... Up X minutes (healthy)
   ```

2. **Verify Cluster Registration:**
   ```bash
   aws ecs list-container-instances --cluster cluster-name
   # Should return container instance ARNs
   ```

3. **Monitor Task Status:**
   ```bash
   aws ecs describe-clusters --clusters cluster-name
   # Should show registeredInstances > 0
   ```

---

## 3. Docker Hub Authentication Issues

### **Problem**
ECS tasks fail to start with Docker image pull errors:
```
CannotPullImageManifestError: Error response from daemon: errors: denied: requested access to the resource is denied unauthorized: authentication required
```

### **Root Cause**
Docker Hub authentication policy changes:
- **n8n/n8n** repository now requires authentication for pulls
- Anonymous access denied for this specific repository
- Rate limiting enforcement

### **Symptoms**
- Tasks fail during image pull phase
- Error mentions "authentication required" or "access denied"
- Network connectivity works (other images pull successfully)
- Specific to n8n/n8n image, not general Docker Hub access

### **Investigation Steps**

**Test Network Connectivity:**
```bash
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["curl -I https://registry-1.docker.io", "docker pull hello-world"]'
# Both should succeed, confirming NAT Gateway connectivity
```

**Test Problematic Image:**
```bash
docker pull n8n/n8n:latest
# Fails with: "pull access denied for n8n/n8n, repository does not exist or may require 'docker login'"
```

**Test Alternative Images:**
```bash
docker pull n8nio/n8n:1.63.4
# Succeeds: official n8nio organization repository doesn't require auth
```

### **Solution: Use Official n8nio Repository**

Update ECS task definitions to use the official repository:

```hcl
# In compute/ecs-tasks.tf
container_definitions = jsonencode([
  {
    name      = "n8n"
    image     = "n8nio/n8n:${var.n8n_image_tag}"  # ← Changed from n8n/n8n
    # ... rest of configuration
  }
])

# Also update worker container:
container_definitions = jsonencode([
  {
    name      = "n8n-worker"
    image     = "n8nio/n8n:${var.n8n_image_tag}"  # ← Changed from n8n/n8n
    # ... rest of configuration
  }
])
```

Update default image tag to match Phase 1 tested version:

```hcl
# In compute/variables.tf
variable "n8n_image_tag" {
  description = "N8N Docker image tag"
  type        = string
  default     = "1.63.4"  # ← Changed from "latest"
}
```

### **Why This Works**
- **n8nio/n8n** is the official n8n organization repository
- No authentication required for public access
- Same Docker image content as n8n/n8n
- Proven working in Phase 1 deployment
- NAT Gateway provides internet connectivity for pulls

### **Alternative Solutions** (if needed)
1. **ECR Public Gallery**: `public.ecr.aws/n8n-io/n8n:latest`
2. **Docker Hub Authentication**: Configure credentials in AWS Secrets Manager
3. **Private ECR**: Push image to your own ECR repository

---

## 4. Container Exit Code 1 Issues

### **Problem**
ECS tasks start but containers immediately exit with exit code 1.

### **Root Cause Analysis**
Based on Phase 1 troubleshooting, likely causes:

#### **Issue A: Missing Explicit Commands**
Architecture differences between development and production:
- Local development may work without explicit commands
- ECS requires explicit command specification

#### **Issue B: Environment Variable Issues**
Missing or incorrect environment variables, especially:
- Database connection parameters
- Redis connection parameters  
- N8N encryption keys

### **Symptoms**
- Tasks start but immediately fail
- Container exit code: 1
- Short-lived containers (seconds, not minutes)
- No healthy targets in load balancer

### **Investigation Steps**

**Check Recent Task Failures:**
```bash
aws ecs list-tasks --cluster cluster-name --desired-status STOPPED
aws ecs describe-tasks --cluster cluster-name --tasks task-arn
```

**Check Container Logs:**
```bash
aws logs tail /ecs/cluster-name/n8n --since 10m
aws logs tail /ecs/cluster-name/n8n-worker --since 10m
```

### **Solutions**

#### **Fix A: Add Explicit Commands**
```hcl
# In compute/ecs-tasks.tf - N8N Main Container
container_definitions = jsonencode([
  {
    name      = "n8n"
    image     = "n8nio/n8n:${var.n8n_image_tag}"
    command   = ["n8n", "start"]  # ← Add explicit command
    # ... rest of configuration
  }
])

# N8N Worker Container
container_definitions = jsonencode([
  {
    name      = "n8n-worker"
    image     = "n8nio/n8n:${var.n8n_image_tag}"
    command   = ["n8n", "worker"]  # ← Add explicit command
    # ... rest of configuration
  }
])
```

#### **Fix B: Verify Environment Variables**
Ensure all required environment variables are present:

```hcl
# Critical environment variables:
environment = [
  {
    name  = "DB_TYPE"
    value = "postgresdb"
  },
  {
    name  = "EXECUTIONS_MODE"
    value = "queue"
  },
  # ... all other required variables
]

# Critical secrets:
secrets = [
  {
    name      = "DB_POSTGRESDB_DATABASE"
    valueFrom = "${var.n8n_secrets_arn}:postgres_db::"
  },
  {
    name      = "N8N_ENCRYPTION_KEY"
    valueFrom = "${var.n8n_secrets_arn}:encryption_key::"
  },
  # ... all other required secrets
]
```

---

## 5. Network Connectivity Problems

### **Problem**
Instance cannot reach internet for Docker image pulls or other external services.

### **Root Cause**
NAT Gateway configuration issues in private subnets.

### **Symptoms**
- Docker pulls timeout or fail
- Instance has no internet connectivity
- Private subnet routing issues

### **Investigation Steps**

**Verify NAT Gateway Status:**
```bash
aws ec2 describe-nat-gateways --query 'NatGateways[?State==`available`].[NatGatewayId,State,SubnetId]'
```

**Check Route Table Configuration:**
```bash
aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=subnet-xxxxx" --query 'RouteTables[0].Routes'
# Should show: 0.0.0.0/0 -> nat-gateway-id
```

**Test Instance Connectivity:**
```bash
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["curl -s https://httpbin.org/ip"]'
# Should return external IP address
```

### **Solution**
Ensure proper NAT Gateway routing is configured in terraform:

```hcl
# Private route table should route 0.0.0.0/0 to NAT Gateway
resource "aws_route" "private" {
  count                  = length(var.private_subnet_ids)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.n8n[count.index].id
}
```

---

## General Troubleshooting Tips

### **Systematic Debugging Approach**
1. **Infrastructure Level**: Verify EC2 instances are running
2. **Network Level**: Test internet connectivity via NAT Gateway
3. **ECS Agent Level**: Confirm agent is running and registered
4. **Container Level**: Check task definitions and image pulls
5. **Application Level**: Verify environment variables and secrets

### **Useful Commands**

**Infrastructure:**
```bash
# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names group-name

# Check EC2 instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
```

**ECS Debugging:**
```bash
# Check cluster status
aws ecs describe-clusters --clusters cluster-name

# List container instances
aws ecs list-container-instances --cluster cluster-name

# Check services
aws ecs describe-services --cluster cluster-name --services service-name

# View task details
aws ecs describe-tasks --cluster cluster-name --tasks task-arn
```

**Network Debugging:**
```bash
# Test NAT Gateway connectivity
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["curl -I https://registry-1.docker.io"]'

# Test Docker pulls
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["docker pull hello-world"]'
```

**Log Analysis:**
```bash
# ECS service logs
aws logs tail /ecs/cluster-name/service-name --since 10m

# Instance user-data logs
aws ssm send-command --instance-ids i-xxxxx --document-name "AWS-RunShellScript" --parameters 'commands=["cat /var/log/user-data.log"]'
```

### **Prevention Strategies**
- **Test incrementally**: Deploy and verify each component before proceeding
- **Use proven versions**: Start with known-working image tags from Phase 1
- **Monitor systematically**: Check each layer (infrastructure → network → ECS → containers)
- **Keep detailed logs**: Enable comprehensive logging for troubleshooting

---

## Summary

The most common deployment issues for n8n on ECS EC2 follow this pattern:

1. **Missing user_data.sh** prevents infrastructure deployment
2. **ECS agent startup issues** prevent container instance registration  
3. **Docker Hub authentication** prevents image pulls
4. **Container configuration issues** prevent successful application startup
5. **Network connectivity problems** prevent external service access

Each issue typically blocks the next phase, so systematic resolution in order is essential. The solutions in this guide address the specific challenges of ECS EC2 deployment compared to ECS Fargate.

For additional support, consult the [AWS ECS documentation](https://docs.aws.amazon.com/ecs/) and [n8n documentation](https://docs.n8n.io/).