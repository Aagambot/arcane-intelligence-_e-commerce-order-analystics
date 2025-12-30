variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecommerce-analytics"
}

variable "environment" {
  type    = string
  default = "production"
}

# S3 Bucket Naming (Using the Account ID pattern you prefer)
variable "raw_orders_bucket_prefix" {
  type    = string
  default = "orders-raw"
}

variable "reports_bucket_prefix" {
  type    = string
  default = "daily-reports"
}

# DynamoDB Config
variable "dynamodb_table_name" {
  type    = string
  default = "orders-table"
}