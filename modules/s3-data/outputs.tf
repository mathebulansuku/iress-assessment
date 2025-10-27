output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "object_keys" {
  description = "Uploaded JSON object keys"
  value       = [for k in keys(aws_s3_object.json) : aws_s3_object.json[k].key]
}

