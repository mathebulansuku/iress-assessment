data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = var.protocol_type
  description   = var.description

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  count                 = var.integrate_lambda ? 1 : 0
  api_id                = aws_apigatewayv2_api.this.id
  integration_type      = "AWS_PROXY"
  integration_uri       = var.lambda_function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda" {
  count     = var.integrate_lambda ? 1 : 0
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "${var.lambda_method} ${var.lambda_route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_apigatewayv2_route" "default" {
  count     = var.integrate_lambda && var.create_default_catch_all ? 1 : 0
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_lambda_permission" "apigw_invoke" {
  count         = var.integrate_lambda ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.this.id}/*/*"
}

resource "aws_apigatewayv2_stage" "this" {
  count       = var.create_default_stage ? 1 : 0
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy

  tags = var.tags
}
