# AWS ECS Fargate CI/CD — Cost Estimate

Estimated monthly costs for this infrastructure running in `us-east-1`.

## Resource Breakdown

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|-------------|
| NAT Gateway | 1 | $0.045/hr + $0.045/GB | ~$32 |
| ALB | 1 | $0.0225/hr + LCU | ~$16 |
| ECS Fargate (dev) | 1-4 tasks | 0.25 vCPU / 0.5 GB | ~$15 |
| ECS Fargate (prod) | 2-8 tasks | 0.25 vCPU / 0.5 GB | ~$30 |
| ECR Storage | ~500 MB | $0.10/GB | ~$1 |
| CloudWatch Logs | ~5 GB | $0.50/GB | ~$3 |
| S3 (state + flow logs) | ~1 GB | $0.023/GB | ~$1 |
| VPC Flow Logs | Enabled | — | ~$5 |
| **Total** | | | **~$103/month** |

## Cost Optimization Tips

- **Dev environment**: Scale to 0 tasks outside business hours using scheduled scaling
- - **NAT Gateway**: Consider NAT instances for non-production (~$4/month vs $32)
  - - **Spot Fargate**: Use Fargate Spot for dev (up to 70% savings)
    - - **Reserved capacity**: Fargate Savings Plans for production (up to 50% off)
      - - **ECR lifecycle**: Auto-delete old images to reduce storage costs
       
        - ## Scaling Cost Impact
       
        - | Scenario | Dev Tasks | Prod Tasks | Est. Monthly |
        - |----------|-----------|------------|-------------|
        - | Minimum | 1 | 2 | ~$85 |
        - | Normal | 2 | 4 | ~$103 |
        - | Peak | 4 | 8 | ~$145 |
       
        - ## Free Tier Coverage
       
        - - GitHub Actions: 2,000 min/month (free for public repos)
          - - ECR: 500 MB storage (first 12 months)
            - - CloudWatch: 5 GB log ingestion
             
              - > Generated with [Infracost](https://www.infracost.io/) methodology. Actual costs may vary.
