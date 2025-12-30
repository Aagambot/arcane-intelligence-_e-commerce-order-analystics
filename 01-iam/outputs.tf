# 01-iam/outputs.tf

output "lambda_order_processor_role_arn" {
  description = "ARN of the Order Processor Lambda role"
  value       = aws_iam_role.order_processor.arn
}

output "lambda_report_generator_role_arn" {
  description = "ARN of the Report Generator Lambda role"
  value       = aws_iam_role.report_generator.arn
}