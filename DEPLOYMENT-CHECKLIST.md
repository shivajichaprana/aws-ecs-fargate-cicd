# Production Deployment Checklist

## ✅ Completed

- [x] Created production ECS service configuration (`ecs-prod.tf`)
- [x] Created blue/green target groups (`alb-prod.tf`)
- [x] Created production IAM OIDC role (`github-role-prod.tf`)
- [x] Added production variables to Terraform
- [x] Added production outputs to Terraform
- [x] Created production repository structure (`nginx-platform-prod/`)
- [x] Created deployment workflow with manual approval
- [x] Created traffic shift workflow
- [x] Created production task definition template
- [x] Created deployment runbook
- [x] Created infrastructure setup guide

## 📋 Next Steps (In Order)

### 1. Deploy Infrastructure (15 minutes)

```bash
cd <your-checkout>/ecs-automation-project/infrastructure

# Review changes
terraform plan

# Deploy
terraform apply

# Verify outputs
terraform output
```

**Expected Resources:**
- Production ECS service (2 tasks)
- Blue target group (active)
- Green target group (empty)
- Weighted ALB listener rule
- Production IAM role

### 2. Create GitHub Repository (5 minutes)

```bash
cd <your-checkout>/nginx-platform-prod

# Initialize git
git init
git add .
git commit -m "Initial production deployment setup"

# Create GitHub repo
gh repo create <your-org>/nginx-platform-prod --public --source=. --push

# Or manually:
# 1. Create repo on GitHub: https://github.com/new
# 2. Push code:
git remote add origin git@github.com:<your-org>/nginx-platform-prod.git
git branch -M main
git push -u origin main
```

### 3. Configure GitHub Environment (5 minutes)

1. Go to: https://github.com/<your-org>/nginx-platform-prod/settings/environments
2. Click **New environment**
3. Name: `production`
4. Check **Required reviewers**
5. Add yourself as reviewer
6. Save

### 4. Verify Infrastructure (5 minutes)

```bash
# Check ECS service
aws ecs describe-services \
  --cluster nginx-fargate-demo-cluster \
  --services nginx-fargate-demo-prod-service \
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount}'

# Check target groups
aws elbv2 describe-target-health \
  --target-group-arn $(cd infrastructure && terraform output -raw prod_blue_target_group_arn)

# Check ALB rule
aws elbv2 describe-rules \
  --rule-arns $(cd infrastructure && terraform output -raw prod_listener_rule_arn)

# Test endpoint
curl http://$(cd infrastructure && terraform output -raw alb_dns_name)/prod
```

### 5. First Production Deployment (10 minutes)

```bash
# Get latest validated image from dev
IMAGE_TAG=$(aws ecr describe-images \
  --repository-name nginx-demo \
  --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' \
  --output text)

echo "Latest image tag: $IMAGE_TAG"
```

Then:
1. Go to: https://github.com/<your-org>/nginx-platform-prod/actions
2. Click **Production Canary Deployment**
3. Click **Run workflow**
4. Enter:
   - image_tag: `<IMAGE_TAG from above>`
   - target_group: `blue`
5. Click **Run workflow**
6. **Approve** the deployment when prompted
7. Wait for completion

### 6. Test Canary Deployment (30 minutes)

#### Deploy to Green (0% traffic)

1. Go to **Actions** → **Production Canary Deployment**
2. Run workflow:
   - image_tag: `<SAME_TAG>`
   - target_group: `green`
3. Approve and wait

#### Shift Traffic Gradually

1. Go to **Actions** → **Traffic Shift (Canary)**

2. **5% Canary**:
   - blue_weight: 95
   - green_weight: 5
   - Approve and monitor for 5 minutes

3. **50% Split**:
   - blue_weight: 50
   - green_weight: 50
   - Approve and monitor for 5 minutes

4. **Full Cutover**:
   - blue_weight: 0
   - green_weight: 100
   - Approve and monitor

#### Test Rollback

1. Go to **Actions** → **Traffic Shift (Canary)**
2. Run workflow:
   - blue_weight: 100
   - green_weight: 0
3. Approve (rollback completes in < 5 seconds)

## 📊 Verification Commands

```bash
# Current traffic weights
aws elbv2 describe-rules \
  --rule-arns $(cd infrastructure && terraform output -raw prod_listener_rule_arn) \
  --query 'Rules[0].Actions[0].ForwardConfig.TargetGroups[*].[TargetGroupArn,Weight]' \
  --output table

# Service status
aws ecs describe-services \
  --cluster nginx-fargate-demo-cluster \
  --services nginx-fargate-demo-prod-service \
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount,taskDef:taskDefinition}'

# CloudWatch logs
aws logs tail /ecs/nginx-fargate-demo-prod --follow

# Target health
aws elbv2 describe-target-health \
  --target-group-arn $(cd infrastructure && terraform output -raw prod_blue_target_group_arn) \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
  --output table
```

## 📚 Documentation

- **Infrastructure Setup**: `infrastructure/PRODUCTION-SETUP.md`
- **Deployment Runbook**: `nginx-platform-prod/docs/DEPLOYMENT.md`
- **Implementation Summary**: `PRODUCTION-IMPLEMENTATION.md`
- **Project README**: `README.md`

## 🔒 Security Checklist

- [x] Separate IAM roles for dev and prod
- [x] Prod role has read-only ECR access (no push)
- [x] Prod role restricted to prod service only
- [x] GitHub environment requires manual approval
- [x] OIDC trust policy restricted to prod repo and environment
- [x] Immutable artifacts (specific image tags)
- [x] Separate CloudWatch log groups

## 💰 Cost Impact

**Additional monthly cost:** ~$30
- 2 ECS Fargate tasks: $15
- Target group: $0.50
- CloudWatch logs: $2
- Data transfer: $5

**Total project:** ~$98/month (dev $68 + prod $30)

## 🚨 Troubleshooting

### Terraform apply fails
```bash
# Check state
terraform state list

# Validate configuration
terraform validate

# Check AWS credentials
aws sts get-caller-identity
```

### ECS service not starting
```bash
# Check service events
aws ecs describe-services \
  --cluster nginx-fargate-demo-cluster \
  --services nginx-fargate-demo-prod-service \
  --query 'services[0].events[0:10]'

# Check logs
aws logs tail /ecs/nginx-fargate-demo-prod --since 10m
```

### GitHub Actions fails
- Verify IAM role ARN in workflow matches Terraform output
- Check GitHub environment is named exactly `production`
- Verify reviewer is added to environment
- Check image tag exists in ECR

### Target group unhealthy
```bash
# Check health check configuration
aws elbv2 describe-target-groups \
  --names nginx-fargate-demo-prod-blue \
  --query 'TargetGroups[0].HealthCheckPath'

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids $(aws ecs describe-services \
    --cluster nginx-fargate-demo-cluster \
    --services nginx-fargate-demo-prod-service \
    --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' \
    --output text)
```

## ✨ Success Criteria

- [ ] Infrastructure deployed successfully
- [ ] Production ECS service running with 2 tasks
- [ ] Blue target group healthy
- [ ] ALB rule routing 100% to blue
- [ ] GitHub repository created
- [ ] Production environment configured with approvals
- [ ] First deployment successful
- [ ] Canary deployment tested
- [ ] Rollback tested and working
- [ ] Monitoring and logs accessible

## 📞 Support

If you encounter issues:
1. Check CloudWatch logs first
2. Review ECS service events
3. Verify IAM permissions
4. Check GitHub Actions logs
5. Review Terraform state

## 🎯 What You've Built

A **production-grade canary deployment system** with:
- ✅ Separate dev and prod environments
- ✅ Manual approval gates
- ✅ Immutable artifacts
- ✅ Zero-downtime deployments
- ✅ Instant rollback capability
- ✅ Blue/green deployment strategy
- ✅ Gradual traffic shifting
- ✅ Complete observability
- ✅ Security best practices
- ✅ Cost-effective architecture

**Ready to deploy!** 🚀
