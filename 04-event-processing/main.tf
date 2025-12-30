terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "ecommerce-analytics-tf-state-205960220424"
    key            = "04-event-processing/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# --- Data Sources ---
# 1. Pull IAM and Storage details
data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = "ecommerce-analytics-tf-state-205960220424"
    key    = "01-iam/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket = "ecommerce-analytics-tf-state-205960220424"
    key    = "02-storage/terraform.tfstate"
    region = "us-east-1"
  }
}

# 2. Automatically ZIP your Python files (including templates.py)
data "archive_file" "report_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/report_generator_payload.zip"
}

# --- Lambda: Report Generator ---
resource "aws_lambda_function" "report_generator" {
  function_name = "${var.project_name}-report-generator"
  role          = data.terraform_remote_state.iam.outputs.lambda_report_generator_role_arn
  handler       = "main.handler"
  runtime       = "python3.10" # Using Python as requested

  filename         = data.archive_file.report_lambda_zip.output_path
  source_code_hash = data.archive_file.report_lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = data.terraform_remote_state.storage.outputs.orders_table_name
      REPORTS_BUCKET = data.terraform_remote_state.storage.outputs.reports_bucket_name
    }
  }
}

# --- EventBridge: The Schedule ---
resource "aws_cloudwatch_event_rule" "daily_report_schedule" {
  name                = "${var.project_name}-report-trigger"
  description         = "Triggers the Report Generator Lambda on a schedule"
  schedule_expression = var.report_schedule
}

resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_report_schedule.name
  target_id = "ReportGenerator"
  arn       = aws_lambda_function.report_generator.arn
}

# Permission for EventBridge to call Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report_schedule.arn
}