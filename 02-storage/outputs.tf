output "raw_orders_bucket_name" {
  value = aws_s3_bucket.raw_orders.id
}

output "reports_bucket_name" {
  value = aws_s3_bucket.reports.id
}

output "orders_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "orders_table_arn" {
  value = aws_dynamodb_table.orders.arn
}