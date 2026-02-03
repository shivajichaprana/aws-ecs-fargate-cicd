# ECS Automation Project

Complete AWS ECS Fargate deployment with automated CI/CD using GitHub Actions and OIDC authentication.

## Project Structure

```
ecs-automation-project/
├── infrastructure/           # Terraform IaC for AWS resources
├── application/              # Nginx application with CI/CD (DEV)
└── DEPLOYMENT-CHECKLIST.md  # Step-by-step deployment guide
```

## Environments

### Development (Automated)
- **Repository**: `shivajichaprana/nginx-platform`
- **ALB Port**: 80
- **Deployment**: Auto-deploy on push to main
- **Service**: nginx-fargate-demo-service (1-4 tasks)

### Production (Manual Canary)
- **Repository**: `shivajichaprana/nginx-platform-prod`
- **ALB Port**: 8080
- **Deployment**: Manual approval required
- **Service**: nginx-fargate-demo-prod-service (2-8 tasks)
- **Strategy**: Blue/green with weighted traffic shifting

## Architecture

```
Developer Push → GitHub Actions (CI)
                      ↓
                 Build & Push to ECR
                      ↓
              GitHub Actions (CD)
                      ↓
         ┌────────────┴────────────┐
         ▼                         ▼
    DEV (Auto)              PROD (Manual)
    Port 80                 Port 8080
    1-4 tasks               2-8 tasks (Blue/Green)
         │                         │
         └────────────┬────────────┘
                      ▼
                 ALB → Users
```

## Quick Start

### 1. Deploy Infrastructure
```bash
cd infrastructure/
terraform init
terraform apply
```

### 2. Access Applications
```bash
# Dev
curl http://$(terraform output -raw alb_dns_name):80

# Prod
curl http://$(terraform output -raw alb_dns_name):8080
```

### 3. Setup Production Repository
See [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)

## Key Features

- ✅ **Keyless Authentication**: OIDC instead of stored AWS credentials
- ✅ **Automated Dev Deployments**: Push to main triggers CI/CD
- ✅ **Manual Prod Deployments**: Approval required + canary releases
- ✅ **Auto-scaling**: CPU/Memory based scaling
- ✅ **High Availability**: Multi-AZ deployment
- ✅ **Security**: Private subnets, security groups, VPC flow logs
- ✅ **Monitoring**: CloudWatch logs and metrics
- ✅ **Circuit Breaker**: Auto-rollback on failed deployments
- ✅ **Instant Rollback**: Change ALB weights in < 5 seconds

## Technology Stack

- **Infrastructure**: Terraform, AWS (VPC, ECS, ALB, ECR)
- **Application**: Nginx, Docker
- **CI/CD**: GitHub Actions
- **Authentication**: OIDC (OpenID Connect)
- **Monitoring**: CloudWatch

## AWS Resources

- **Account**: 975050061334
- **Region**: us-east-1
- **ECS Cluster**: nginx-fargate-demo-cluster
- **ECR Repository**: nginx-demo
- **Dev Repo**: shivajichaprana/nginx-platform
- **Prod Repo**: shivajichaprana/nginx-platform-prod

## Security

- No AWS credentials stored in GitHub
- OIDC temporary tokens (1-hour expiration)
- Scoped IAM permissions (dev vs prod)
- Private subnets for containers
- VPC Flow Logs enabled
- S3 bucket encryption

## Cost

Estimated monthly cost: ~$103
- NAT Gateway: $32
- ALB: $16
- ECS Fargate (dev): $15
- ECS Fargate (prod): $30
- Other: $10

## Documentation

- **Deployment Guide**: [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)
- **Infrastructure Setup**: [infrastructure/PRODUCTION-SETUP.md](./infrastructure/PRODUCTION-SETUP.md)
- **Dev Application**: [application/README.md](./application/README.md)
- **Prod Deployment**: See `nginx-platform-prod` repository

## Maintenance

- Infrastructure changes: Update Terraform code
- Dev changes: Push to GitHub (auto-deploys)
- Prod changes: Manual deployment with approval
- Rollback: Deploy previous image tag or change ALB weights

## License

MIT
