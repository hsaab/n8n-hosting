# N8N on AWS ECS with Terraform

This Terraform configuration deploys n8n to AWS ECS Fargate, closely mirroring your docker-compose setup while leveraging AWS managed services.

## Architecture Overview

```
Internet → ALB (Public Subnets)
              ↓
         ECS Service (Private Subnets)
              ↓
    ┌─────────┴──────────┐
    │                    │
N8N Main            N8N Worker
    │                    │
    └────┬──────┬────────┘
         │      │
    PostgreSQL  Redis
    (ECS Tasks in Private Subnets)
         │      │
        EFS (Persistent Storage)
```

## Key Components Explained

### 1. **ECS Cluster** (`main.tf`)
- **What it is**: A logical grouping of tasks/services
- **Learning point**: Unlike docker-compose on a single machine, ECS distributes containers across multiple servers

### 2. **Task Definitions** (`ecs-tasks.tf`)
- **What it is**: Blueprint for your containers (like docker-compose services)
- **Key concepts**:
  - CPU/Memory must use specific Fargate combinations
  - `awsvpc` network mode gives each task its own network interface
  - Service discovery replaces Docker's internal DNS

### 3. **ECS Services** (`ecs-tasks.tf`)
- **What it is**: Manages running instances of task definitions
- **Learning point**: Services ensure desired count of tasks are always running (self-healing)

### 4. **Application Load Balancer** (`alb.tf`)
- **What it is**: Routes external traffic to your containers
- **Replaces**: Port mapping from docker-compose (5678:5678)
- **Benefits**: HTTPS termination, health checks, multiple targets

### 5. **Service Discovery** (`main.tf`)
- **What it is**: Internal DNS for container communication
- **How it works**: Creates `postgres.n8n.local` and `redis.n8n.local` hostnames
- **Replaces**: Docker's automatic container linking

### 6. **Secrets Manager** (`secrets.tf`)
- **What it is**: Secure storage for passwords
- **Replaces**: `.env` file from docker-compose
- **Benefits**: Encrypted at rest, audit logging, rotation support

### 7. **EFS (Elastic File System)** (`main.tf`)
- **What it is**: Shared persistent storage
- **Replaces**: Docker volumes
- **Benefits**: Survives container restarts, shared across tasks

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)
3. An existing VPC with:
   - At least 2 private subnets (for ECS tasks)
   - At least 2 public subnets (for ALB)
   - Internet Gateway attached
   - NAT Gateway/Instance for private subnet internet access

## Deployment Steps

### 1. Clone and Navigate
```bash
cd terraform/ecs-n8n
```

### 2. Create Your Variables File
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit terraform.tfvars
Fill in your actual values:
- VPC and Subnet IDs from your existing infrastructure
- Strong passwords (different from the example!)
- Optional: ACM certificate ARN for HTTPS

### 4. Initialize Terraform
```bash
terraform init
```

### 5. Review the Plan
```bash
terraform plan
```
This shows you exactly what will be created.

### 6. Deploy
```bash
terraform apply
```
Type 'yes' when prompted.

### 7. Get Your N8N URL
After deployment completes:
```bash
terraform output alb_dns_name
```
Access n8n at: `http://<alb-dns-name>`

## Understanding the Deployment

### Container Communication
- **PostgreSQL**: Accessible at `postgres.n8n.local:5432`
- **Redis**: Accessible at `redis.n8n.local:6379`
- **N8N**: Exposed via ALB on port 80/443

### Persistent Data
- PostgreSQL data: `/postgres` on EFS
- Redis data: `/redis` on EFS
- N8N data: `/n8n` on EFS

### Logs
View logs in CloudWatch:
- `/ecs/n8n-cluster/n8n`
- `/ecs/n8n-cluster/n8n-worker`
- `/ecs/n8n-cluster/postgres`
- `/ecs/n8n-cluster/redis`

## Cost Optimization Tips

### Current Setup (Learning Mode)
- Running PostgreSQL and Redis as ECS tasks
- Good for learning ECS concepts
- Higher cost due to multiple Fargate tasks

### Production Optimization
1. **Use RDS for PostgreSQL** (~$15/month for db.t4g.micro)
   - Managed backups
   - Automatic updates
   - Multi-AZ for high availability

2. **Use ElastiCache for Redis** (~$13/month for cache.t4g.micro)
   - Managed Redis
   - Automatic failover
   - Backup and restore

3. **Consider ECS on EC2** instead of Fargate
   - Lower cost for consistent workloads
   - More control over infrastructure

## Monitoring

### CloudWatch Metrics
- ECS Service metrics (CPU, Memory)
- ALB metrics (Request count, Target health)
- Custom n8n metrics via CloudWatch agent

### Health Checks
- ALB performs health checks on `/healthz`
- ECS replaces unhealthy tasks automatically

## Troubleshooting

### Common Issues

1. **Tasks not starting**
   ```bash
   aws ecs describe-tasks --cluster n8n-cluster --tasks <task-arn>
   ```
   Check `stoppedReason` field

2. **Cannot access n8n**
   - Check security groups
   - Verify ALB target health
   - Review CloudWatch logs

3. **Database connection issues**
   - Verify service discovery DNS resolution
   - Check security group rules
   - Ensure PostgreSQL is healthy

### Useful Commands

```bash
# List all services
aws ecs list-services --cluster n8n-cluster

# Check service status
aws ecs describe-services --cluster n8n-cluster --services n8n-service

# View logs
aws logs tail /ecs/n8n-cluster/n8n --follow

# Force new deployment
aws ecs update-service --cluster n8n-cluster --service n8n-service --force-new-deployment
```

## Clean Up

To avoid ongoing charges:
```bash
terraform destroy
```

**Note**: EFS data persists after destroy. Delete manually if needed.

## Next Steps for Learning

1. **Add Auto-scaling**: Configure ECS Service auto-scaling based on CPU/memory
2. **Implement CI/CD**: Use CodePipeline to deploy on git push
3. **Add Custom Domain**: Configure Route53 with your domain
4. **Enhance Security**: Add WAF, implement VPC endpoints
5. **Optimize Costs**: Migrate to RDS/ElastiCache, use Spot instances

## Key Differences from Docker Compose

| Docker Compose | ECS Equivalent | Why Different |
|---------------|----------------|---------------|
| `docker-compose up` | `terraform apply` | Infrastructure as Code |
| `links` | Service Discovery | DNS-based service communication |
| `volumes` | EFS | Distributed persistent storage |
| `ports` | ALB + Target Groups | Load balancing and routing |
| `.env` file | Secrets Manager | Secure secret storage |
| `restart: always` | ECS Service | Self-healing with desired count |
| Single host | Multiple AZs | High availability |

## Resources

- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [N8N Documentation](https://docs.n8n.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)