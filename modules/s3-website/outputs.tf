output "bucket_name" {
  description = "Website S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "website_endpoint" {
  description = "Website endpoint URL"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "bucket_arn" {
  description = "Website S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name for CloudFront origin"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
