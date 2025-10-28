output "tf_state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}

output "api_url" {
  description = "Base API URL"
  value       = coalesce(module.api_gateway.invoke_url, module.api_gateway.api_endpoint)
}

output "frontend_bucket" {
  description = "Frontend website S3 bucket"
  value       = module.frontend_website.bucket_name
}

output "frontend_url" {
  description = "Frontend website URL (S3 website endpoint)"
  value       = module.frontend_website.website_endpoint
}
