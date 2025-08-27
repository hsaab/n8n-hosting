# N8N ECS Fargate Deployment - Troubleshooting Guide

This guide documents common issues encountered when deploying n8n on AWS ECS Fargate and their detailed solutions.

## Table of Contents
1. [Docker Image Pull Failures](#1-docker-image-pull-failures)
2. [EFS Mount Failures](#2-efs-mount-failures)  
3. [Docker Command Parsing Issues](#3-docker-command-parsing-issues)
4. [EFS Permission Denied Errors](#4-efs-permission-denied-errors)
5. [Database SSL Connection Issues](#5-database-ssl-connection-issues)

---

## 1. Docker Image Pull Failures

### **Problem**
ECS tasks fail to start with error:
```
CannotPullContainerError: pull image manifest has been retried 7 time(s): 
failed to resolve ref docker.io/library/redis:6-alpine
```

### **Root Cause**
ECS tasks cannot reach the internet to pull Docker images from Docker Hub because:
- Tasks are placed in public subnets but have `assign_public_ip = false`
- Without public IP, tasks cannot access external repositories

### **Symptoms**
- All ECS services show status "PENDING"  
- Tasks fail during image pull phase
- CloudWatch logs show network timeout errors
- Works locally with docker-compose but fails in ECS

### **Solution**
Enable public IP assignment for ECS tasks in public subnets:

```hcl
# In ecs-tasks.tf - for all ECS services
resource "aws_ecs_service" "redis" {
  # ... other configuration ...
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true  # ← Change from false to true
  }
}
```

**Apply to all services**: n8n main, n8n worker, and Redis services.

### **Why This Works**
- Public IP enables direct internet access for Docker Hub
- Alternative solutions include NAT Gateway (more expensive) or VPC endpoints (more complex)
- For production, consider private subnets with NAT Gateway for better security

---

## 2. EFS Mount Failures  

### **Problem**
ECS tasks fail with ResourceInitializationError:
```
ResourceInitializationError: failed to invoke EFS utils commands to set up EFS volumes: 
stderr: Failed to resolve "fs-xxxxx.efs.region.amazonaws.com"
```

### **Root Cause Analysis**
Multiple EFS-related issues:

#### **Issue A: Wrong Security Group**
Redis service was using `redis` security group instead of `ecs_tasks` security group, preventing EFS access.

#### **Issue B: Non-existent EFS Directories**
EFS volume configurations referenced directories that didn't exist:
```hcl
# ❌ These directories don't exist on EFS
root_directory = "/redis"
root_directory = "/n8n"
```

### **Symptoms**
- Tasks stuck in PENDING state after image pull succeeds
- EFS mount failures in CloudWatch logs
- Tasks restart repeatedly

### **Solutions**

#### **Fix A: Correct Security Group**
```hcl
# In ecs-tasks.tf
resource "aws_ecs_service" "redis" {
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]  # ← Use ecs_tasks, not redis
    assign_public_ip = true
  }
}
```

#### **Fix B: Use Root Directory**
```hcl
# In all EFS volume configurations
volume {
  name = "redis-storage"
  efs_volume_configuration {
    file_system_id     = aws_efs_file_system.n8n_storage.id
    root_directory     = "/"  # ← Use root instead of subdirectories
    transit_encryption = "ENABLED"
  }
}
```

### **Why This Works**
- `ecs_tasks` security group has the necessary EFS access rules
- Using root directory (`/`) avoids assumptions about existing subdirectories
- EFS will automatically create subdirectories as needed by applications

---

## 3. Docker Command Parsing Issues

### **Problem**
N8N containers fail with command errors:
```
Error: Command 'start' not found
Error: Command 'worker' not found  
```

### **Root Cause**
Architecture differences between development and production environments:

- **Local (Mac M1/M2)**: Uses ARM64 Docker images with different entrypoint behavior
- **ECS Fargate**: Uses AMD64 Docker images with different command parsing
- Docker-compose works locally but same configuration fails in ECS

### **Symptoms**  
- Local docker-compose runs successfully
- ECS tasks start but immediately exit with command errors
- n8n main service gets unknown "start" command
- n8n worker service can't recognize "worker" command

### **Deep Dive Analysis**
The issue stems from Docker image architecture differences:

1. **Local Development**: 
   - Mac M1/M2 pulls ARM64 images automatically
   - These images have entrypoint scripts that handle implicit commands
   
2. **ECS Fargate**:
   - Always uses AMD64 images  
   - Different entrypoint behavior requires explicit command specification

### **Solution**
Add explicit commands to ECS task definitions:

```hcl
# N8N Main Container
container_definitions = jsonencode([
  {
    name    = "n8n"
    image   = var.n8n_image
    command = ["n8n", "start"]  # ← Explicit command
    # ... other configuration
  }
])

# N8N Worker Container  
container_definitions = jsonencode([
  {
    name    = "n8n-worker"
    image   = var.n8n_image  
    command = ["n8n", "worker"]  # ← Explicit command
    # ... other configuration
  }
])
```

### **Why This Works**
- Explicit commands override any entrypoint ambiguity
- Commands are architecture-independent
- Matches the intended behavior from docker-compose implicit commands

### **Prevention Tips**
- Always test ECS deployments, don't assume docker-compose compatibility
- Consider using multi-arch images when available
- Document architecture-specific behaviors for future deployments

---

## 4. EFS Permission Denied Errors

### **Problem**
N8N containers start but fail to create application directories:
```
EACCES: permission denied, mkdir '/data/.n8n'
chown: /data: Operation not permitted
```

### **Root Cause**
EFS permission model conflicts:
- Container runs as user `1000` (n8n user)
- EFS root directory owned by `root:root` with restrictive permissions  
- Container cannot create directories in `/data` mount point

### **Detailed Analysis**
EFS behavior differs from local Docker volumes:
- **Local Docker**: Volumes inherit container user permissions automatically
- **EFS**: Maintains Linux filesystem permissions, requires explicit configuration

### **Failed Attempts**
Multiple approaches were tried unsuccessfully:

1. **Manual chown commands** - Failed due to EFS root ownership
2. **Init containers** - Added complexity without solving core issue  
3. **Running as root** - Security concern and didn't persist across restarts

### **Solution: EFS Access Points**
Implement EFS Access Point with POSIX user configuration:

```hcl
# In main.tf
resource "aws_efs_access_point" "n8n_data" {
  file_system_id = aws_efs_file_system.n8n_storage.id

  # Set POSIX user for all file operations
  posix_user {
    uid = 1000  # n8n user
    gid = 1000  # n8n group  
  }

  # Create dedicated directory with proper ownership
  root_directory {
    path = "/n8n-data"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000  
      permissions = 755
    }
  }
}
```

Update EFS volume configuration to use access point:
```hcl
# In ecs-tasks.tf  
efs_volume_configuration {
  file_system_id          = aws_efs_file_system.n8n_storage.id
  root_directory          = "/"
  transit_encryption      = "ENABLED"
  authorization_config {
    access_point_id = aws_efs_access_point.n8n_data.id
    iam            = "ENABLED"
  }
}
```

Add IAM permissions for EFS access points:
```hcl
# In main.tf
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
          # ... other EFS permissions
        ]
        Resource = aws_efs_access_point.n8n_data.arn
      }
    ]
  })
}
```

### **Why This Works**
- **Access Points** act as application-specific entry points to EFS
- **POSIX user mapping** ensures all file operations use specified uid/gid
- **Automatic ownership** eliminates need for manual chown commands
- **IAM integration** provides secure, managed access control

### **Benefits**
- No manual permission management required
- Secure isolation between different applications
- Consistent permissions across container restarts
- Eliminates "Operation not permitted" errors

---

## 5. Database SSL Connection Issues

### **Problem**
N8N successfully starts but cannot connect to RDS PostgreSQL:
```
DatabaseError: no pg_hba.conf entry for host "172.31.x.x", user "n8n_user", 
database "n8nhs", no encryption
```

### **Root Cause**
RDS PostgreSQL security configuration mismatch:
- **RDS Default**: Enforces SSL connections for security
- **N8N Configuration**: Not configured for SSL by default
- **pg_hba.conf**: PostgreSQL host-based authentication rejects non-SSL connections

### **Detailed Analysis**

#### **PostgreSQL SSL Enforcement**
RDS PostgreSQL instances enforce SSL by default through:
1. **Parameter Group**: `rds.force_ssl = 1` (default)
2. **pg_hba.conf**: Host-based authentication rules  
3. **Security Best Practice**: Encrypt data in transit

#### **N8N SSL Configuration**
N8N requires explicit SSL mode configuration:
- Without configuration, attempts unencrypted connection
- RDS rejects connection due to security policy
- Error message indicates "no encryption" issue

### **Solution**

#### **Option A: Disable SSL Requirement (Development)**
For development environments, disable SSL enforcement:

```hcl
# Create custom parameter group
resource "aws_db_parameter_group" "n8n_postgres" {
  family = "postgres16"
  name   = "${var.cluster_name}-postgres-params"

  parameter {
    name  = "rds.force_ssl"
    value = "0"  # Disable SSL requirement
  }
}

# Apply to RDS instance
resource "aws_db_instance" "n8n" {
  # ... other configuration ...
  parameter_group_name = aws_db_parameter_group.n8n_postgres.name
}
```

Configure N8N to disable SSL:
```hcl
# In ECS task definition environment variables
{
  name  = "DB_POSTGRESDB_SSL_MODE"  
  value = "disable"
}
```

**Important**: Requires RDS instance reboot to apply parameter changes:
```bash
aws rds reboot-db-instance --db-instance-identifier your-instance-id
```

#### **Option B: Enable SSL (Production Recommended)**
For production environments, configure N8N to use SSL:

```hcl
# In ECS task definition environment variables
{
  name  = "DB_POSTGRESDB_SSL_MODE"
  value = "require"  # or "prefer" for fallback capability
}
```

Keep default RDS SSL enforcement (recommended for production).

### **Why This Works**

#### **Development Approach (Option A)**:
- Disables RDS SSL requirement at database level
- Allows unencrypted connections from applications
- Simpler configuration for development/testing

#### **Production Approach (Option B)**:
- Maintains security best practices
- Encrypts database connections in transit  
- Requires proper SSL certificate handling

### **Production Considerations**
- **Security**: Always use SSL in production environments
- **Compliance**: Many standards require encryption in transit
- **Performance**: SSL adds minimal overhead with modern hardware
- **Maintenance**: SSL certificates need proper rotation and management

### **Verification Steps**
1. **Check Parameter Status**:
   ```bash
   aws rds describe-db-instances --db-instance-identifier your-instance \
     --query "DBInstances[0].DBParameterGroups[0]"
   ```

2. **Monitor Application Logs**:
   ```bash  
   aws logs tail /ecs/cluster-name/n8n --since 5m
   ```

3. **Test Database Connection**:
   - Look for successful n8n initialization messages
   - Verify web interface accessibility

---

## General Troubleshooting Tips

### **Systematic Debugging Approach**
1. **Check ECS Service Status**: Identify which services are failing
2. **Review Task Definitions**: Verify resource allocations and configurations  
3. **Examine CloudWatch Logs**: Look for specific error messages
4. **Validate Network Configuration**: Ensure proper subnet and security group setup
5. **Test Layer by Layer**: Isolate issues (network → storage → application → database)

### **Common Commands**
```bash
# Check ECS service status
aws ecs describe-services --cluster cluster-name --services service-name

# View recent logs  
aws logs tail /ecs/cluster-name/service-name --since 10m

# Check RDS status
aws rds describe-db-instances --db-instance-identifier instance-id

# Verify EFS mount targets
aws efs describe-mount-targets --file-system-id fs-xxxxx
```

### **Prevention Strategies**
- **Infrastructure as Code**: Use Terraform for reproducible deployments
- **Environment Parity**: Test in environments similar to production
- **Monitoring**: Set up CloudWatch alarms for service health
- **Documentation**: Keep detailed deployment and troubleshooting notes

---

## Summary

This troubleshooting guide covers the most common issues when deploying n8n on AWS ECS Fargate. The problems typically cascade:

1. **Network issues** prevent image pulling
2. **Storage issues** prevent container startup  
3. **Command issues** prevent application launch
4. **Permission issues** prevent data persistence
5. **Database issues** prevent full functionality

Each issue builds upon the previous, so systematic resolution is essential. Following this guide should help you deploy n8n successfully on ECS Fargate and troubleshoot any issues that arise.

For additional support, consult the [AWS ECS documentation](https://docs.aws.amazon.com/ecs/) and [n8n documentation](https://docs.n8n.io/).