# E-Commerce Order Analytics Pipeline - Terraform Architecture

## Project Structure

```
terraform/
├── backend-config/
│   └── backend.tf                    # Remote state configuration
├── 00-foundation/
│   ├── main.tf                       # VPC, Subnets, Security Groups
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 01-iam/
│   ├── main.tf                       # IAM Roles & Policies
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 02-storage/
│   ├── main.tf                       # S3 Buckets & DynamoDB
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 03-api-ingestion/
│   ├── main.tf                       # API Gateway + Lambda (Order Processor)
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 04-event-processing/
│   ├── main.tf                       # EventBridge + Lambda (Report Generator)
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 05-notification/
│   ├── main.tf                       # SES + SNS
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── 06-monitoring/
│   ├── main.tf                       # CloudWatch Alarms, Log Groups
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── terraform.tfvars                  # Global variables
```

## Module Dependency Chain

```
00-foundation (VPC, Security Groups)
    ↓
01-iam (IAM Roles & Policies)
    ↓
02-storage (S3 + DynamoDB) ← Depends on IAM
    ↓
03-api-ingestion (API Gateway + Lambda) ← Depends on IAM, Storage
    ↓
04-event-processing (EventBridge + Lambda) ← Depends on IAM, Storage
    ↓
05-notification (SES + SNS) ← Depends on IAM
    ↓
06-monitoring (CloudWatch) ← Depends on all Lambda functions
```

## Deployment Order

### Initial Deployment
```bash
# Step 1: Setup remote backend
cd backend-config
terraform init
terraform apply

# Step 2: Foundation (VPC, Networking)
cd ../00-foundation
terraform init
terraform apply

# Step 3: IAM Roles and Policies
cd ../01-iam
terraform init
terraform apply

# Step 4: Storage Layer
cd ../02-storage
terraform init
terraform apply

# Step 5: API and Ingestion
cd ../03-api-ingestion
terraform init
terraform apply

# Step 6: Event Processing
cd ../04-event-processing
terraform init
terraform apply

# Step 7: Notifications
cd ../05-notification
terraform init
terraform apply

# Step 8: Monitoring
cd ../06-monitoring
terraform init
terraform apply
```

### Adding New Services (Without Redeployment)

**Example: Adding a new Lambda function for data transformation**

1. Create new module: `07-data-transformation/`
2. Reference existing resources using remote state:
```hcl
data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "02-storage/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "01-iam/terraform.tfstate"
    region = "us-east-1"
  }
}
```
3. Deploy only the new module:
```bash
cd 07-data-transformation
terraform init
terraform apply
```

## State Management Strategy

### Remote Backend Configuration
- **S3 Bucket**: Stores Terraform state files
- **DynamoDB Table**: Provides state locking
- **Separate State Files**: Each module has its own state file
- **State File Naming**: `{module-name}/terraform.tfstate`

### Benefits
✅ Independent module deployment
✅ Parallel development by teams
✅ Reduced blast radius
✅ Easy rollback per module
✅ Clear dependency tracking

## Acceptable Redeployment Scenarios

### When Redeployment is Required:
1. **VPC Changes** (00-foundation)
   - Changing CIDR blocks
   - Adding/removing subnets
   - Modifying route tables

2. **Security Group Updates** (00-foundation)
   - Adding new security rules that affect multiple services

3. **IAM Policy Changes** (01-iam)
   - Modifying permissions that affect existing resources

### When Redeployment is NOT Required:
✅ Adding new Lambda functions
✅ Creating new S3 buckets
✅ Adding CloudWatch alarms
✅ Creating new DynamoDB tables
✅ Adding SES configurations
✅ Creating new EventBridge rules

## Cross-Module Data Sharing

### Using Outputs
Module outputs are consumed by dependent modules via `terraform_remote_state`:

**Example from 01-iam/outputs.tf:**
```hcl
output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
  description = "ARN of Lambda execution role"
}
```

**Example from 03-api-ingestion/main.tf:**
```hcl
data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "01-iam/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_lambda_function" "order_processor" {
  role = data.terraform_remote_state.iam.outputs.lambda_role_arn
  # ... other configuration
}
```

## Tagging Strategy

All resources use consistent tags:
```hcl
tags = {
  Project     = "ecommerce-analytics"
  Module      = "api-ingestion"
  Environment = var.environment
  ManagedBy   = "terraform"
  Owner       = "data-engineering-team"
}
```

## Variables Management

### Global Variables (terraform.tfvars)
```hcl
aws_region      = "us-east-1"
environment     = "production"
project_name    = "ecommerce-analytics"
state_bucket    = "my-terraform-state-bucket"
state_lock_table = "terraform-state-lock"
```

### Module-Specific Variables
Each module has its own `variables.tf` with defaults and descriptions

## Best Practices Implemented

1. ✅ **Remote State Backend** - S3 + DynamoDB
2. ✅ **State File Separation** - One per module
3. ✅ **Output Sharing** - Via terraform_remote_state
4. ✅ **Modular Design** - Independent, reusable modules
5. ✅ **Variable Management** - Centralized and module-specific
6. ✅ **Tagging Strategy** - Consistent across all resources
7. ✅ **Documentation** - README in each module
8. ✅ **Version Pinning** - Terraform and provider versions locked
9. ✅ **Security** - IAM least privilege, encryption enabled
10. ✅ **Scalability** - Easy to extend with new modules

## Module Grouping Rationale

### Tightly Coupled (Same Module):
- **API Gateway + Lambda (Order Processor)** - Direct integration
- **EventBridge + Lambda (Report Generator)** - Event-driven pair
- **S3 + DynamoDB** - Both storage layer, often queried together
- **SES + SNS** - Notification services, configured together

### Independent Modules:
- **Foundation** - Core networking, rarely changes
- **IAM** - Security layer, referenced by all
- **Monitoring** - Observability, added last

## Troubleshooting Common Issues

### Issue: Module dependency not found
**Solution**: Ensure dependent modules are deployed first and outputs are defined

### Issue: State lock error
**Solution**: Check DynamoDB lock table, manually release if needed

### Issue: Resource already exists
**Solution**: Import existing resource or use `terraform import`

## Next Steps

1. Deploy modules in order (00 → 06)
2. Test each module independently
3. Verify outputs are accessible to dependent modules
4. Document any custom changes in module README files
5. Set up automated deployment pipeline (GitHub Actions)