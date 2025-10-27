locals {
  json_files = fileset(var.source_dir, "**/*.json")
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "json" {
  for_each     = toset(local.json_files)
  bucket       = aws_s3_bucket.this.id
  key          = var.key_prefix != "" ? "${var.key_prefix}/${each.value}" : each.value
  source       = "${var.source_dir}/${each.value}"
  content_type = "application/json"
  etag         = filemd5("${var.source_dir}/${each.value}")
}

