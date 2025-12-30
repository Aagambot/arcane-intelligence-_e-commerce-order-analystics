# 03-api-ingestion/outputs.tf

output "api_url" {
  description = "The public endpoint to send order data to"
  # We use the stage resource to get the correct URL
  value       = "${aws_api_gateway_stage.prod.invoke_url}/order"
}

output "lambda_function_name" {
  description = "The name of the Order Processor Lambda function"
  value       = aws_lambda_function.order_processor.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Order Processor Lambda function"
  value       = aws_lambda_function.order_processor.arn
}

output "api_gateway_id" {
  description = "The ID of the REST API"
  value       = aws_api_gateway_rest_api.order_api.id
}