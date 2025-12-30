output "lambda_function_name" {
  value = aws_lambda_function.report_generator.function_name
}

output "report_generator_lambda_arn" {
  value = aws_lambda_function.report_generator.arn
}