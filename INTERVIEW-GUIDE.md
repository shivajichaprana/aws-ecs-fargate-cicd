# Interview Talking Points

## Project Summary
Built a production-grade AWS ECS Fargate deployment with automated CI/CD, blue/green deployments, and zero-downtime releases using GitHub Actions and OIDC authentication.

## Technical Highlights

### 1. Infrastructure as Code (Terraform)
**What I did:**
- Designed and implemented complete AWS infrastructure using Terraform
- Managed 25+ AWS resources across VPC, ECS, ALB, IAM, ECR
- Used Terraform modules for reusability and maintainability

**Why it matters:**
- Infrastructure is version-controlled and reproducible
- Easy to replicate across environments
- Reduces manual errors and configuration drift

**Interview talking point:**
"I used Terraform to provision the entire infrastructure, which allowed me to destroy and recreate the environment multiple times during testing without manual AWS console clicks."

### 2. Keyless Authentication (OIDC)
**What I did:**
- Implemented GitHub OIDC provider for AWS authentication
- Eliminated need for long-lived AWS credentials in GitHub
- Configured separate IAM roles for dev and prod with least privilege

**Why it matters:**
- Security best practice (no credentials to leak)
- Temporary tokens with 1-hour expiration
- Audit trail via CloudTrail

**Interview talking point:**
"Instead of storing AWS access keys in GitHub secrets, I used OIDC which generates temporary credentials. This is more secure and follows AWS's recommended approach."

### 3. Blue/Green Canary Deployment
**What I did:**
- Implemented blue/green deployment strategy for production
- Created weighted traffic shifting mechanism using ALB
- Enabled instant rollback by changing ALB listener weights

**Why it matters:**
- Zero-downtime deployments
- Test new version with 0% traffic before going live
- Rollback in < 5 seconds vs minutes for redeployment

**Interview talking point:**
"For production, I implemented a canary deployment where the new version (GREEN) gets 0% traffic initially. After testing, we gradually shift traffic from BLUE to GREEN. If issues arise, we can instantly rollback by changing ALB weights."

### 4. Separate Dev/Prod Pipelines
**What I did:**
- Dev: Auto-deploy on push to main (port 80)
- Prod: Manual approval required (port 8080)
- Separate GitHub repositories and IAM roles

**Why it matters:**
- Prevents accidental production deployments
- Different risk profiles for different environments
- Compliance with change management policies

**Interview talking point:**
"I separated dev and prod into different workflows. Dev auto-deploys for fast iteration, while prod requires manual approval and uses a different port (8080) to avoid routing conflicts."

### 5. Auto-scaling and High Availability
**What I did:**
- Configured ECS auto-scaling based on CPU/Memory (50% threshold)
- Multi-AZ deployment across 2 availability zones
- Circuit breaker for automatic rollback on failures

**Why it matters:**
- Handles traffic spikes automatically
- Survives AZ failures
- Reduces manual intervention

**Interview talking point:**
"The application automatically scales from 1 to 4 tasks in dev and 2 to 8 in prod based on CPU/memory. It's deployed across multiple AZs for high availability."

## Challenges Solved

### Challenge 1: Terraform State Management
**Problem:** Existing IAM role wasn't tracked in Terraform state
**Solution:** Used `terraform import` to bring existing resource under management
**Learning:** Always check AWS console vs Terraform state for drift

### Challenge 2: Blue/Green Traffic Routing
**Problem:** How to deploy new version without affecting live traffic
**Solution:** Created separate target groups with weighted routing
**Learning:** ALB listener rules support weighted target groups for canary releases

### Challenge 3: Service Dependencies
**Problem:** ECS services depend on ALB, which depends on target groups
**Solution:** Used Terraform `depends_on` and proper resource ordering
**Learning:** Infrastructure dependencies matter for clean creation/destruction

## Metrics & Results

- **Deployment Time**: ~3 minutes (build + deploy)
- **Rollback Time**: < 5 seconds (ALB weight change)
- **Availability**: Multi-AZ with auto-healing
- **Cost**: ~$103/month (estimated for full deployment)
- **Security**: Zero stored credentials, OIDC-based auth

## What I Would Do Differently

1. **Add monitoring/alerting**: CloudWatch alarms for CPU, memory, failed deployments
2. **Implement secrets management**: AWS Secrets Manager for sensitive configs
3. **Add automated testing**: Integration tests before production deployment
4. **Use Fargate Spot**: For dev environment to reduce costs
5. **Implement WAF**: Web Application Firewall for security

## Questions I Can Answer

1. "Walk me through your deployment process"
2. "How do you handle rollbacks?"
3. "What security measures did you implement?"
4. "How does your infrastructure scale?"
5. "What would you do to reduce costs?"
6. "How do you prevent accidental production deployments?"
7. "Explain your blue/green deployment strategy"
8. "How do you manage infrastructure as code?"

## Demo Flow (If Asked)

1. Show GitHub repository structure
2. Explain Terraform infrastructure code
3. Walk through GitHub Actions workflows
4. Demonstrate blue/green deployment concept
5. Show how to rollback using ALB weights
6. Discuss security (OIDC, IAM roles)
7. Explain monitoring and logging setup

## Key Takeaways

✅ **Production-ready**: Not just a tutorial, but production-grade setup
✅ **Security-first**: OIDC, least privilege IAM, private subnets
✅ **Automation**: Full CI/CD with minimal manual intervention
✅ **Reliability**: Multi-AZ, auto-scaling, circuit breaker
✅ **Best practices**: IaC, blue/green, canary deployments
