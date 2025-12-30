# Module 00: Foundation Infrastructure

## Overview
This module creates the foundational networking infrastructure for the E-Commerce Order Analytics Pipeline, including VPC, subnets, security groups, and VPC endpoints.

## Resources Created
- **VPC** with DNS support and hostnames enabled
- **2 Public Subnets** across different availability zones
- **2 Private Subnets** across different availability zones
- **Internet Gateway** for public internet access
- **Route Tables** for public and private subnets
- **Security Groups** for Lambda and API Gateway
- **VPC Endpoints** for S3 and DynamoDB (cost optimization)

## Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                        │
│                                                             │
│  ┌────────────────────┐      ┌────────────────────┐       │
│  │  Public Subnet 1   │      │  Public Subnet 2   │       │
│  │   10.0.1.0/24      │      │   10.0.2.0/24      │       │
│  │   (us-east-1a)     │      │   (us-east-1b)     │       │
│  └────────────────────┘      └────────────────────┘       │
│           │                           │                     │
│           └───────────┬───────────────┘                    │
│                       │                                     │
│              ┌────────▼────────┐                           │
│              │ Internet Gateway │                           │
│              └─────────────────┘                           │
│                                                             │
│  ┌────────────────────┐      ┌────────────────────┐       │
│  │  Private Subnet 1  │      │  Private Subnet 2  │       │
│  │   10.0.11.0/24     │      │   10.0.12.0/24     │       │
│  │   (us-east-1a)     │      │   (us-east-1b)     │       │
│  └────────────────────┘      └────────────────────┘       │
│           │                           │                     │
│           └───────────┬───────────────┘                    │
│                       │                                     │
│              ┌────────▼────────┐                           │
│              │  VPC Endpoints  │                           │
│              │  (S3, DynamoDB) │                           │
│              └─────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.5.0 installed
3. Backend infrastructure deployed (backend-config module)

## Deployment Steps

### 1. Initialize Terraform
```bash
cd 00-foundation
terraform init
```

### 2. Review Configuration
```bash
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply
```

### 4. Verify Outputs
```bash
terraform output
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-east-1` | No |
| `project_name` | Project name for resource naming | `ecommerce-analytics` | No |
| `environment` | Environment (dev/staging/production) | `production` | No |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` | No |
| `enable_nat_gateway` | Enable NAT Gateway for private subnets | `false` | No |
| `enable_vpc_endpoints` | Enable VPC endpoints | `true` | No |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `lambda_security_group_id` | Security group ID for Lambda functions |
| `api_gateway_security_group_id` | Security group ID for API Gateway |

## Dependencies
- **Depends On**: backend-config module (for remote state)
- **Required By**: All other modules (IAM, Storage, API, etc.)

## Cost Considerations
- **VPC**: Free
- **Subnets**: Free
- **Internet Gateway**: Free
- **VPC Endpoints**: ~$7/month per endpoint (S3 is free, DynamoDB charges per GB)
- **NAT Gateway** (if enabled): ~$32/month + data transfer costs

💡 **Cost Optimization**: VPC endpoints are enabled by default to reduce data transfer costs and improve security.

## Security Features
- ✅ Public subnets for resources needing internet access
- ✅ Private subnets for sensitive workloads
- ✅ Security groups with least privilege rules
- ✅ VPC endpoints to avoid public internet routing
- ✅ Multi-AZ deployment for high availability

## Troubleshooting

### Issue: "Error creating VPC"
**Solution**: Check AWS account limits for VPCs in your region

### Issue: "CIDR block conflicts"
**Solution**: Ensure your VPC CIDR doesn't conflict with existing VPCs

### Issue: "Subnet creation fails"
**Solution**: Verify availability zones are available in your region

## Updating This Module

### Adding New Subnets
1. Modify the subnet resources in `main.tf`
2. Update outputs in `outputs.tf`
3. Run `terraform plan` to review changes
4. Run `terraform apply`

### Modifying Security Groups
⚠️ **Warning**: Changes to security groups may affect existing services. Review impact before applying.

## Cleanup
```bash
# WARNING: This will destroy all networking infrastructure
terraform destroy
```

⚠️ **Note**: You must destroy all dependent modules first (API, Lambda, Storage, etc.) before destroying foundation infrastructure.

## Module State
- **State File**: `s3://ecommerce-analytics-terraform-state/00-foundation/terraform.tfstate`
- **Lock Table**: `terraform-state-lock`

## Next Steps
After deploying this module, proceed to:
1. **Module 01-iam**: Create IAM roles and policies
2. **Module 02-storage**: Deploy S3 and DynamoDB

## Support
For issues or questions, contact the platform team or create an issue in the repository.