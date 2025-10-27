output "api_id" {
  description = "HTTP API ID"
  value       = aws_apigatewayv2_api.this.id
}

output "api_arn" {
  description = "HTTP API ARN"
  value       = aws_apigatewayv2_api.this.arn
}

output "api_endpoint" {
  description = "Base API endpoint"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "stage_name" {
  description = "Stage name (if created)"
  value       = try(aws_apigatewayv2_stage.this[0].name, null)
}

locals {
  stage_prefix = var.create_default_stage && var.stage_name != "$default" ? "/${var.stage_name}" : ""
}

output "invoke_url" {
  description = "Full invoke base URL"
  value       = var.create_default_stage ? "${aws_apigatewayv2_api.this.api_endpoint}${local.stage_prefix}" : null
}

output "lambda_invoke_url" {
  description = "Invoke URL for the Lambda-backed route (if enabled)"
  value       = var.create_default_stage && var.integrate_lambda ? "${aws_apigatewayv2_api.this.api_endpoint}${local.stage_prefix}${var.lambda_route_path}" : null
}
