variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecommerce-analytics"
}

variable "admin_email" {
  description = "The email address to receive daily reports"
  type        = string
  default     = "aagammehta373@gmail.com" # CHANGE THIS
}