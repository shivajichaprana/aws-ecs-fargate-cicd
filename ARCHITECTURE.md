# Architecture Overview

## System Design

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Actions                          │
│  ┌──────────────────────┐      ┌──────────────────────────┐    │
│  │   DEV Pipeline       │      │   PROD Pipeline          │    │
│  │   (Auto Deploy)      │      │   (Manual Approval)      │    │
│  └──────────┬───────────┘      └──────────┬───────────────┘    │
└─────────────┼──────────────────────────────┼────────────────────┘
              │                              │
              │ OIDC Auth                    │ OIDC Auth
              ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Account                            │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    Amazon ECR                          │   │
│  │              nginx-demo:v1.0, v2.0, v3.0...           │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                Application Load Balancer               │   │
│  │  ┌──────────────────┐      ┌──────────────────────┐   │   │
│  │  │  Port 80 (DEV)   │      │  Port 8080 (PROD)    │   │   │
│  │  │  100% Traffic    │      │  Blue/Green Weights  │   │   │
│  │  └────────┬─────────┘      └──────┬───────────────┘   │   │
│  └───────────┼────────────────────────┼───────────────────┘   │
│              │                        │                        │
│  ┌───────────▼────────────┐  ┌────────▼──────────────────┐   │
│  │   ECS Service (DEV)    │  │  ECS Service (PROD)       │   │
│  │   1-4 tasks            │  │  ┌─────────────────────┐  │   │
│  │   Auto-scaling         │  │  │ BLUE (100%)         │  │   │
│  │                        │  │  │ 2-8 tasks           │  │   │
│  └────────────────────────┘  │  └─────────────────────┘  │   │
│                              │  ┌─────────────────────┐  │   │
│                              │  │ GREEN (0%)          │  │   │
│                              │  │ Canary deployment   │  │   │
│                              │  └─────────────────────┘  │   │
│                              └──────────────────────────┘   │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                   │   │
│  │  ┌──────────────┐  ┌──────────────┐                   │   │
│  │  │ Public AZ1   │  │ Public AZ2   │  (ALB)            │   │
│  │  └──────┬───────┘  └──────┬───────┘                   │   │
│  │         │                  │                            │   │
│  │  ┌──────▼───────┐  ┌──────▼───────┐                   │   │
│  │  │ Private AZ1  │  │ Private AZ2  │  (ECS Tasks)      │   │
│  │  └──────────────┘  └──────────────┘                   │   │
│  │         │                                               │   │
│  │    NAT Gateway → Internet Gateway                      │   │
│  └────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. CI/CD Pipeline
- **Dev**: Auto-deploy on push to main
- **Prod**: Manual approval + canary deployment
- **Authentication**: OIDC (no stored credentials)

### 2. Networking
- **VPC**: Multi-AZ for high availability
- **Subnets**: Public (ALB) + Private (ECS tasks)
- **NAT Gateway**: Outbound internet for private subnets

### 3. Compute
- **ECS Fargate**: Serverless containers
- **Auto-scaling**: CPU/Memory based (50% threshold)
- **Circuit Breaker**: Auto-rollback on failures

### 4. Load Balancing
- **Dev**: Port 80, single target group
- **Prod**: Port 8080, blue/green target groups
- **Health Checks**: 30s interval, 2 consecutive checks

### 5. Deployment Strategy

#### Development
```
Push → Build → ECR → Deploy → 100% Traffic
```

#### Production (Blue/Green Canary)
```
1. Deploy GREEN service (0% traffic)
2. Manual approval required
3. Test GREEN endpoint
4. Gradually shift traffic (0% → 25% → 50% → 100%)
5. Instant rollback if needed (change ALB weights)
```

## Security

- **No AWS credentials in GitHub**: OIDC temporary tokens
- **Private subnets**: ECS tasks not publicly accessible
- **Security groups**: Least privilege access
- **IAM roles**: Separate dev/prod permissions
- **VPC Flow Logs**: Network traffic monitoring

## Monitoring

- **CloudWatch Logs**: Container logs per service
- **CloudWatch Metrics**: CPU, memory, request count
- **ECS Events**: Deployment status, task failures
- **ALB Metrics**: Target health, response times

## Cost Optimization

- **Fargate Spot**: Not used (prioritized availability)
- **Auto-scaling**: Scale down during low traffic
- **NAT Gateway**: Single gateway (not per AZ)
- **ALB**: Shared across dev/prod environments

## Disaster Recovery

- **Multi-AZ**: Automatic failover
- **Circuit Breaker**: Auto-rollback on 3 failures
- **Blue/Green**: Instant rollback via ALB weights
- **ECR**: Immutable image tags for version control
