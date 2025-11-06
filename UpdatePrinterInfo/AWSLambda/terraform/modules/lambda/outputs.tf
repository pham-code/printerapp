output "lambda_function_arn" {
  value = aws_lambda_function.printer_ink_monitor_lambda.arn
}

output "api_gateway_endpoint" {
  description = "The full invoke URL for the API Gateway endpoint"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}${var.environment}${aws_api_gateway_resource.resource.path}"
}