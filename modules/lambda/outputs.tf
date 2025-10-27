output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

