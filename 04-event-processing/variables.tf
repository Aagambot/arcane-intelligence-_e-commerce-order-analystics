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

variable "report_schedule" {
  description = "Cron expression for the report (Default: Every day at midnight)"
  type        = string
  default     = "cron(0 0 * * ? *)" 
}