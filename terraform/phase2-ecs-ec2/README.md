# Phase 2: N8N on ECS with EC2 + ElastiCache

This phase demonstrates deploying n8n on ECS using EC2 instances with managed ElastiCache Redis. You'll learn the differences between serverless (Fargate) and self-managed (EC2) compute, plus the benefits of managed services like ElastiCache.

## 🎯 Phase 2 Learning Objectives

### Key Differences from Phase 1
- **Compute**: EC2 instances instead of Fargate
- **Redis**: ElastiCache instead of ECS task
- **Cost**: Lower cost for persistent workloads
- **Control**: More infrastructure control and configuration options

### What You'll Learn
1. **ECS Capacity Providers**: Mix On-Demand and Spot instances
2. **Instance Auto Scaling**: Infrastructure-level scaling vs container-level
3. **ElastiCache Redis**: Managed Redis with high availability
4. **Cost Optimization**: Spot instances and right-sizing strategies
5. **Hybrid Architecture**: Mix of managed services and containers

## 🏗️ Architecture Overview

```
Internet Gateway
       ↓
Application Load Balancer (Public Subnets)
       ↓
Auto Scaling Group - ECS Cluster (Private Subnets)
├── EC2 Instance 1 (ECS Agent)
│   ├── n8n main task
│   └── PostgreSQL task
├── EC2 Instance 2 (ECS Agent)
│   ├── n8n worker task
│   └── Available capacity
└── ElastiCache Redis Cluster (Multi-AZ)
    └── Automatic failover enabled

Persistent Storage: EFS (shared across instances)
```

## 🔍 Key Components Explained

### 1. **ECS Capacity Providers**
- **What**: Manages how ECS scales EC2 instances
- **Benefits**: 
  - Mix On-Demand (reliable) and Spot (cheap) instances
  - Automatic instance scaling based on task demand
  - Cost optimization while maintaining availability

### 2. **ElastiCache Redis**
- **What**: AWS-managed Redis service
- **Benefits vs ECS Redis**:
  - ✅ Zero maintenance (patching, backups)
  - ✅ Multi-AZ high availability 
  - ✅ Automatic failover
  - ✅ Enhanced monitoring and alerting
  - ❌ Higher minimum cost (~$13/month)

### 3. **EC2 Auto Scaling Group**
- **What**: Manages EC2 instances for your ECS cluster
- **Benefits vs Fargate**:
  - ✅ Lower cost for persistent workloads
  - ✅ More control over instance types
  - ✅ Access to instance-level metrics
  - ❌ More infrastructure to manage

## 🚀 Deployment Instructions

### Prerequisites
Same as Phase 1, plus:
- Understanding of EC2 instance types
- Familiarity with Auto Scaling Groups (optional but helpful)

### 1. Navigate to Phase 2
```bash
cd terraform/phase2-ecs-ec2
```

### 2. Copy Variables Template
```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit Configuration
Key new variables for Phase 2:
```hcl
# EC2 Configuration
instance_type = "t3.medium"      # Instance type for ECS cluster
min_size      = 1                # Minimum instances
max_size      = 3                # Maximum instances
desired_size  = 2                # Desired instances

# Spot instance configuration (cost savings)
spot_instance_percentage = 50    # 50% spot instances
spot_max_price          = "0.05" # Maximum price per hour

# ElastiCache Configuration  
redis_node_type              = "cache.t4g.micro"  # Redis instance type
redis_num_cache_clusters     = 1                  # Single node for learning
redis_transit_encryption     = false              # Disable for simplicity
redis_auth_token            = ""                  # No auth for learning
```

### 4. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 5. Monitor Deployment
```bash
# Check ECS cluster
aws ecs describe-clusters --clusters n8n-cluster

# Check ElastiCache  
aws elasticache describe-replication-groups --replication-group-id n8n-cluster-redis

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names n8n-cluster-asg
```

## 💰 Cost Analysis

### Expected Monthly Costs (us-east-1)

**EC2 Instances (2 × t3.medium)**
- On-Demand: $60.72/month  
- 50% Spot: ~$35/month (varies with spot prices)

**ElastiCache Redis (cache.t4g.micro)**
- $13.14/month

**Other Resources**
- EFS: ~$3/month
- ALB: $18.25/month  
- Data transfer: ~$5/month

**Total: ~$75-95/month** (vs ~$120/month for equivalent Fargate)

### Cost Optimization Tips
1. **Use Spot Instances**: 50-70% cost savings
2. **Right-size instances**: Monitor CPU/memory usage
3. **Schedule scaling**: Scale down during off-hours
4. **Reserved Instances**: 30-60% savings for predictable workloads

## 🔧 Configuration Options

### Instance Types Comparison
| Instance Type | vCPU | Memory | Cost/month | Use Case |
|--------------|------|--------|------------|----------|
| t3.micro | 2 | 1GB | $7.59 | Testing only |
| t3.small | 2 | 2GB | $15.18 | Light workloads |
| t3.medium | 2 | 4GB | $30.36 | Recommended |
| t3.large | 2 | 8GB | $60.72 | Heavy workloads |

### ElastiCache Options
| Node Type | Memory | Cost/month | Use Case |
|-----------|--------|------------|----------|
| cache.t4g.micro | 555MB | $13.14 | Learning/dev |
| cache.t4g.small | 1.37GB | $26.28 | Small production |
| cache.r7g.large | 12.32GB | $157.68 | High performance |

## 📊 Performance Comparisons

### Phase 1 (Fargate) vs Phase 2 (EC2) Expected Performance

| Metric | Phase 1 (Fargate) | Phase 2 (EC2 + ElastiCache) |
|--------|-------------------|------------------------------|
| **Container startup** | 30-60s | 5-15s |
| **Redis performance** | Good | Excellent |
| **Cost (persistent)** | High | Medium |
| **Maintenance** | None | EC2 patching |
| **Scalability** | Excellent | Good |

## 🔍 Monitoring and Troubleshooting

### Key Metrics to Monitor
1. **ECS Service metrics**: CPU, Memory utilization
2. **EC2 metrics**: Instance CPU, Memory, Network
3. **ElastiCache metrics**: CPU, Memory usage, Hit rate
4. **Auto Scaling metrics**: Scale-out/in events

### Common Issues and Solutions

**1. Tasks not placing on instances**
```bash
# Check cluster capacity
aws ecs describe-clusters --clusters n8n-cluster --include ATTACHMENTS

# Check service events
aws ecs describe-services --cluster n8n-cluster --services n8n-service
```

**2. ElastiCache connection issues**
- Verify security groups allow port 6379
- Check VPC and subnet configuration
- Ensure endpoints are correctly configured in task definitions

**3. Auto Scaling not working**
```bash
# Check scaling policies
aws autoscaling describe-policies --auto-scaling-group-name n8n-cluster-asg

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names n8n-cluster-*
```

### Useful Commands
```bash
# SSH to ECS instance (if needed)
aws ec2-instance-connect ssh --instance-id i-1234567890abcdef0

# View ECS agent logs
docker logs ecs-agent

# Check ElastiCache endpoint
aws elasticache describe-replication-groups \
  --replication-group-id n8n-cluster-redis \
  --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint'
```

## 🎓 Phase 2 Success Criteria

- [ ] **N8N deployed on EC2 instances** instead of Fargate
- [ ] **ElastiCache Redis working** for queue management
- [ ] **Mixed capacity**: Both On-Demand and Spot instances running
- [ ] **Auto Scaling**: Instances scale based on ECS task demand
- [ ] **Cost comparison**: Understand cost differences vs Phase 1
- [ ] **Monitor hybrid metrics**: Both container and infrastructure metrics

## ➡️ Next Steps

After completing Phase 2:

1. **Experiment with scaling**
   - Add load to trigger auto-scaling
   - Test spot instance interruption handling
   
2. **Cost optimization**
   - Try different instance types
   - Adjust spot instance percentage
   
3. **Performance testing**
   - Compare Redis performance vs Phase 1
   - Test ElastiCache failover scenarios

4. **Prepare for Phase 3 (Kubernetes)**
   - Compare ECS concepts to Kubernetes equivalents
   - Consider how this setup would translate to K8s

## 🔄 Rollback to Phase 1

If needed, you can easily switch back to Phase 1:
```bash
cd ../phase1-ecs-fargate
terraform apply
```

## 📚 Additional Resources

- [ECS Capacity Providers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)
- [ElastiCache Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/BestPractices.html)
- [EC2 Spot Instance Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
- [ECS Task Placement](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement.html)