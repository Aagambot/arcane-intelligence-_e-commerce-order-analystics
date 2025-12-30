# Module 01: IAM Roles and Policies

## Overview
This module creates all IAM roles and policies required for the E-Commerce Order Analytics Pipeline. It follows the principle of least privilege, granting only necessary permissions to each service.

## Resources Created
- **Lambda Order Processor Role** - For processing incoming orders
- **Lambda Report Generator Role** - For generating daily reports
- **API Gateway Execution Role** - For invoking Lambda functions
- **EventBridge Execution Role** - For triggering scheduled Lambda functions
- **CloudWatch Logs Role** - For centralized logging

## IAM Roles Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                      IAM Roles & Policies                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Lambda Order Processor Role                                │
│  ├── CloudWatch Logs (Write)                                │
│  ├── S3 (PutObject, GetObject) - orders-raw bucket         │
│  ├── DynamoDB (PutItem, GetItem, UpdateItem) - orders      │
│  └── VPC (Network Interface Management)                     │
│                                                             │
│  Lambda Report Generator Role                               │
│  ├── CloudWatch Logs (Write)                                │
│  ├── DynamoDB (Query, Scan, GetItem) - orders              │
│  ├── S3 (PutObject, GetObject) - reports bucket            │
│  ├── SES (SendEmail, SendRawEmail)                         │
│  └── VPC (Network Interface Management)                     │
│                                                             │
│  API Gateway Role                                           │
│  ├── Lambda (InvokeFunction) - all project Lambdas         │
│  └── CloudWatch Logs (Write)                                │
│                                                             │
│  EventBridge Role                                           │
│  └── Lambda (InvokeFunction) - all project Lambdas         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0 installed
3. Backend infrastructure deployed (backend-config module)
4. Foundation infrastructure deployed (00-foundation module)

## Deployment Steps

### 1. Initialize Terraform
```bash
cd 01-iam
terraform init
```

### 2. Review Planned Changes
```bash
terraform plan
```

### 3. Deploy IAM Resources
```bash
terraform apply
```

### 4. Verify Outputs
```bash
terraform output
terraform output lambda_order_processor_role_arn
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-east-1` | No |
| `project_name` | Project name for resource naming | `ecommerce-analytics` | No |
| `environment` | Environment (dev/staging/production) | `production` | No |
| `enable_lambda_vpc_access` | Enable VPC permissions for Lambda | `true` | No |
| `enable_xray_tracing` | Enable X-Ray tracing permissions | `false` | No |
| `enable_ses_email` | Enable SES email permissions | `true` | No |
| `cloudwatch_log_retention_days` | Log retention period | `30` | No |

## Outputs

| Output | Description |
|--------|-------------|
| `lambda_order_processor_role_arn` | ARN of Order Processor Lambda role |
| `lambda_report_generator_role_arn` | ARN of Report Generator Lambda role |
| `api_gateway_role_arn` | ARN of API Gateway role |
| `eventbridge_role_arn` | ARN of EventBridge role |
| `iam_roles_summary` | Summary of all created IAM roles |

## Permissions Breakdown

### Lambda Order Processor Permissions
```json
{
  "CloudWatch": ["CreateLogGroup", "CreateLogStream", "PutLogEvents"],
  "S3": ["PutObject", "GetObject"],
  "DynamoDB": ["PutItem", "GetItem", "UpdateItem"],
  "EC2": ["CreateNetworkInterface", "DescribeNetworkInterfaces", "DeleteNetworkInterface"]
}
```

### Lambda Report Generator Permissions
```json
{
  "CloudWatch": ["CreateLogGroup", "CreateLogStream", "PutLogEvents"],
  "DynamoDB": ["Query", "Scan", "GetItem"],
  "S3": ["PutObject", "GetObject"],
  "SES": ["SendEmail", "SendRawEmail"],
  "EC2": ["CreateNetworkInterface", "DescribeNetworkInterfaces", "DeleteNetworkInterface"]
}
```

## Dependencies
- **Depends On**: 
  - backend-config (for remote state)
  - 00-foundation (optional, for VPC-related permissions)
- **Required By**: 
  - 02-storage (references IAM roles)
  - 03-api-ingestion (uses Lambda and API Gateway roles)
  - 04-event-processing (uses EventBridge and Lambda roles)

## Security Best Practices

### ✅ Implemented
- Least privilege access principle
- Resource-specific ARNs where possible
- Separate roles for different Lambda functions
- No wildcard permissions on sensitive actions
- VPC permissions isolated to necessary functions

### 🔒 Security Considerations
- IAM policies use specific resource ARNs when possible
- Wildcards are used only for CloudWatch Logs (standard practice)
- SES permissions allow sending to any email (can be restricted)
- Lambda functions have separate roles for different responsibilities

## Cost Considerations
- **IAM Roles**: Free
- **IAM Policies**: Free
- **API Calls**: Free (within AWS Free Tier limits)

💡 IAM resources are completely free in AWS.

## Troubleshooting

### Issue: "Error assuming role"
**Solution**: Verify the trust relationship policy allows the correct service principal

### Issue: "Access Denied" errors in Lambda
**Solution**: Check that IAM policies have been applied and propagated (can take 30-60 seconds)

### Issue: "Policy size exceeded"
**Solution**: Split large policies into multiple inline policies or use managed policies

## Modifying IAM Policies

### Adding New Permissions
1. Edit the `main.tf` file
2. Add new permissions to the relevant policy
3. Run `terraform plan` to review changes
4. Run `terraform apply`

⚠️ **Warning**: IAM changes may require redeployment of Lambda functions or other services.

### Example: Add S3 List Permission
```hcl
# In lambda_order_processor_policy
{
  Effect = "Allow"
  Action = [
    "s3:ListBucket"
  ]
  Resource = "arn:aws:s3:::${var.project_name}-orders-raw-*"
}
```

## Testing IAM Permissions

### Test Lambda Role
```bash
aws sts assume-role \
  --role-arn $(terraform output -raw lambda_order_processor_role_arn) \
  --role-session-name test-session
```

### Verify Policy
```bash
aws iam get-role-policy \
  --role-name ecommerce-analytics-lambda-order-processor-role \
  --policy-name ecommerce-analytics-lambda-order-processor-policy
```

## Cleanup
```bash
# WARNING: This will destroy all IAM roles and policies
terraform destroy
```

⚠️ **Note**: Ensure no Lambda functions or services are using these roles before destroying.

## Module State
- **State File**: `s3://ecommerce-analytics-terraform-state/01-iam/terraform.tfstate`
- **Lock Table**: `terraform-state-lock`

## Updating Without Redeployment

✅ **Can be updated without affecting other modules:**
- Adding new IAM roles
- Adding permissions to existing roles (non-breaking changes)
- Adding new policies

⚠️ **May affect dependent modules:**
- Removing permissions from existing roles
- Deleting IAM roles currently in use
- Renaming roles (will break references)

## Next Steps
After deploying this module, proceed to:
1. **Module 02-