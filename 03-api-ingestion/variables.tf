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

variable "lambda_memory_size" {
  description = "Memory allocation for the Order Processor Lambda"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout for the Order Processor Lambda"
  type        = number
  default     = 30
}