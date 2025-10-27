terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
  }

   backend "s3" {
    bucket         = "iress-assessment-tf-state-2025"
    key            = "global/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "iress-assessment-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "af-south-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "iress-assessment-tf-state-2025"
 
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}



resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_dynamodb_table" "tf_lock" {
  name         = "iress-assessment-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

}


