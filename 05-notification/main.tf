terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "ecommerce-analytics-tf-state-205960220424"
    key            = "05-notification/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# --- SES: Email Identity ---
resource "aws_ses_email_identity" "admin" {
  email = var.admin_email
}