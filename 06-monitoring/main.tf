terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "ecommerce-analytics-tf-state-205960220424"
    key            = "06-monitoring/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# --- Data Sources: Pull names from all modules ---
data "terraform_remote_state" "ingestion" {
  backend = "s3"
  config = {
    bucket = "ecommerce-analytics-tf-state-205960220424"
    key    = "03-api-ingestion/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "processing" {
  backend = "s3"
  config = {
    bucket = "ecommerce-analytics-tf-state-205960220424"
    key    = "04-event-processing/terraform.tfstate"
    region = "us-east-1"
  }
}

# --- CloudWatch Dashboard ---
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-health"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: Order Processor Success vs Errors
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", data.terraform_remote_state.ingestion.outputs.lambda_function_name],
            [".", "Errors", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Order Ingestion: Invocations vs Errors"
        }
      },
      # Widget 2: Report Generator Health
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", data.terraform_remote_state.processing.outputs.lambda_function_name]
          ]
          period = 86400 # 24 hours (once a day)
          stat   = "Sum"
          region = var.aws_region
          title  = "Daily Report Generator Runs"
        }
      }
    ]
  })
}

# --- CloudWatch Alarm: Alert if Ingestion Fails ---
resource "aws_cloudwatch_metric_alarm" "ingestion_errors" {
  alarm_name          = "HighIngestionErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This alarm triggers if the Order Processor Lambda fails."
  dimensions = {
    FunctionName = data.terraform_remote_state.ingestion.outputs.lambda_function_name
  }
}