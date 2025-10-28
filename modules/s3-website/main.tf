locals {
  files = fileset(var.source_dir, "**/*")
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# IMPORTANT: Public access may be blocked at the account level.
# Ensure the account-level S3 Public Access Block allows this bucket policy.
resource "aws_s3_bucket_policy" "public_read" {
  count  = var.public_read ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = ["${aws_s3_bucket.this.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_object" "files" {
  for_each = { for f in local.files : f => f }

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${var.source_dir}/${each.value}"

  # Basic content-type mapping for common web files (no-regex to avoid escaping issues)
  content_type = try(
    lookup({
      ".html" = "text/html",
      ".css"  = "text/css",
      ".js"   = "application/javascript",
      ".json" = "application/json",
      ".png"  = "image/png",
      ".jpg"  = "image/jpeg",
      ".jpeg" = "image/jpeg",
      ".svg"  = "image/svg+xml",
    }, lower(format(".%s", element(split(each.value, "."), length(split(each.value, ".")) - 1))), "application/octet-stream"),
    "application/octet-stream"
  )

  etag = filemd5("${var.source_dir}/${each.value}")
}
