resource "aws_s3_bucket" "lambda_deployment_bucket" {

  bucket = var.s3_bucket_name

  tags = {
    Name        = "bucket-${var.project_name}-${var.environment}-lambda-deployment"
    Environment = var.environment
  }
}

resource "aws_s3_object" "lambda_deployment_zip" {
  bucket = aws_s3_bucket.lambda_deployment_bucket.id
  key    = "AWSLambda-0.0.1-SNAPSHOT.jar"
  source = "../target/AWSLambda-0.0.1-SNAPSHOT.jar"
  etag   = filemd5("../target/AWSLambda-0.0.1-SNAPSHOT.jar")
}

resource "aws_lambda_function" "printer_ink_monitor_lambda" {
  function_name    = "PrinterInkMonitorLambda"
  handler          = "com.example.printerapp.LambdaHandler::handleRequest"
  runtime          = "java11"
  s3_bucket        = aws_s3_bucket.lambda_deployment_bucket.id
  s3_key           = aws_s3_object.lambda_deployment_zip.key
  source_code_hash = filebase64sha256("../target/AWSLambda-0.0.1-SNAPSHOT.jar")
  role             = var.lambda_iam_role_arn
  timeout          = 30
  memory_size      = 1024

  vpc_config {
    subnet_ids         = [var.lambda_private_subnet_id]
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      SPRING_DATASOURCE_URL = "jdbc:mysql://${var.db_private_ip}:${var.db_port}/${var.db_name}"
      SPRING_DATASOURCE_USERNAME = var.db_user
      SPRING_DATASOURCE_PASSWORD = var.db_pass
    }
  }

  tags = {
    Name        = "lambda-${var.project_name}-${var.environment}-ink-monitor"
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.printer_ink_monitor_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "api-${var.project_name}-${var.environment}-printer-ink-monitor"
  description = "API for the Printer Ink Monitor Lambda"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "printer-status"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.printer_ink_monitor_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

