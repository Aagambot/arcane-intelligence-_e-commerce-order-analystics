# 01-iam/variables.tf

variable "aws_region" {
  description = "AWS region where IAM resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used for IAM resource naming"
  type        = string
  default     = "ecommerce-analytics"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production"
  }
}

variable "enable_lambda_vpc_access" {
  description = "Enable VPC access permissions for Lambda functions"
  type        = bool
  default     = true
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing permissions for Lambda"
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention value"
  }
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs for IAM policies (uses wildcard if not specified)"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs for IAM policies (uses wildcard if not specified)"
  type        = list(string)
  default     = []
}

variable "enable_ses_email" {
  description = "Enable SES email sending permissions"
  type        = bool
  default     = true
}

variable "ses_verified_emails" {
  description = "List of SES verified email addresses (empty = all)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum session duration for IAM roles in seconds"
  type        = number
  default     = 3600
  
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1 hour) and 43200 (12 hours)"
  }
}