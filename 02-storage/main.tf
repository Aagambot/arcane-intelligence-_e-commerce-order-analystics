terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "ecommerce-analytics-tf-state-205960220424"
    key            = "02-storage/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Fetch account ID for unique S3 names
data "aws_caller_identity" "current" {}

# --- S3: Raw Data Lake ---
resource "aws_s3_bucket" "raw_orders" {
  bucket = "${var.project_name}-${var.raw_orders_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
  
  tags = { Name = "Raw Orders Store" }
}

# --- S3: Reports Store ---
resource "aws_s3_bucket" "reports" {
  bucket = "${var.project_name}-${var.reports_bucket_prefix}-${data.aws_caller_identity.current.account_id}"
  
  tags = { Name = "Analytics Reports Store" }
}

# --- DynamoDB: Orders Table ---
resource "aws_dynamodb_table" "orders" {
  name         = "${var.project_name}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id" # Partition Key
  range_key    = "timestamp" # Sort Key

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  tags = { Environment = var.environment }
}