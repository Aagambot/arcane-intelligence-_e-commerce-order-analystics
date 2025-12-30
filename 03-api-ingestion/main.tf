terraform {
  required_version = ">= 1.5.0"
  backend "s3" {
    bucket         = "ecommerce-analytics-tf-state-205960220424"
    key            = "03-api-ingestion/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_payload.zip"
}

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

# --- Lambda: Order Processor ---
resource "aws_lambda_function" "order_processor" {
  function_name = "${var.project_name}-order-processor"
  role          = data.terraform_remote_state.iam.outputs.lambda_order_processor_role_arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = data.terraform_remote_state.storage.outputs.orders_table_name
      S3_BUCKET      = data.terraform_remote_state.storage.outputs.raw_orders_bucket_name
    }
  }
}

# --- API Gateway: REST API (v1) ---
resource "aws_api_gateway_rest_api" "order_api" {
  name = "${var.project_name}-api"
}

resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  parent_id   = aws_api_gateway_rest_api.order_api.root_resource_id
  path_part   = "order" # Must match your frontend URL: .../prod/order
}

# --- 1. POST Method (The actual order logic) ---
resource "aws_api_gateway_method" "post_order" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_int" {
  rest_api_id             = aws_api_gateway_rest_api.order_api.id
  resource_id             = aws_api_gateway_resource.order.id
  http_method             = aws_api_gateway_method.post_order.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.order_processor.invoke_arn
}

# --- 2. OPTIONS Method (The CORS Fix) ---
resource "aws_api_gateway_method" "options_order" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_int" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.options_order.http_method
  type        = "MOCK" # MOCK integration allows AWS to handle CORS automatically
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.options_order.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_int_resp" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.options_order.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_method_response.options_200]
}

# --- 3. Deployment & Permissions ---
resource "aws_api_gateway_deployment" "order_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.order_api.id
  
  # Trigger redeployment on ANY configuration change to avoid "stale" 403 errors
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.order.id,
      aws_api_gateway_method.post_order.id,
      aws_api_gateway_method.options_order.id,
      aws_api_gateway_integration.lambda_int.id,
      aws_api_gateway_integration.options_int.id,
    ]))
  }

  lifecycle { create_before_destroy = true }
  depends_on = [aws_api_gateway_integration.lambda_int, aws_api_gateway_integration.options_int]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.order_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_processor.function_name
  principal     = "apigateway.amazonaws.com"
  # This pattern allows ANY stage/method to invoke the lambda
  source_arn    = "${aws_api_gateway_rest_api.order_api.execution_arn}/*/*"
}

resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  response_type = "DEFAULT_4XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.order_api.id
  response_type = "DEFAULT_5XX"
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin" = "'*'"
  }
}