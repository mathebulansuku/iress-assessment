terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }

  }

  backend "s3" {
    bucket         = "iress-assessment-tf-state-2025"
    key            = "env/dev/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "iress-assessment-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name

  tags = local.common_tags

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = var.tf_state_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.tf_state_sse_algorithm
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
  name         = var.tf_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "random_id" "dataset_suffix" {
  byte_length = var.random_suffix_byte_length
}

module "dataset_bucket" {
  source      = "./modules/s3-data"
  bucket_name = "${var.dataset_bucket_prefix}-${random_id.dataset_suffix.hex}"
  source_dir  = coalesce(var.dataset_source_dir, "${path.root}/dataset")
  tags        = local.common_tags
}

module "lambda" {
  source         = "./modules/lambda"
  name           = var.lambda_name
  dataset_bucket = module.dataset_bucket.bucket_name
  dataset_key    = var.lambda_dataset_key
  tags           = local.common_tags
}

module "api_gateway" {
  source               = "./modules/api-gateway"
  name                 = var.api_name
  protocol_type        = var.api_protocol_type
  create_default_stage = var.api_create_default_stage
  stage_name           = var.api_stage_name
  auto_deploy          = var.api_auto_deploy

  integrate_lambda    = var.api_integrate_lambda
  lambda_function_arn = module.lambda.arn
  lambda_route_path   = var.api_lambda_route_path
  lambda_method       = var.api_lambda_method

  tags = local.common_tags
}

module "frontend_website" {
  source      = "./modules/s3-website"
  bucket_name = "${var.frontend_bucket_prefix}-${random_id.dataset_suffix.hex}"
  source_dir  = coalesce(var.frontend_source_dir, "${path.root}/frontend")
  tags        = local.common_tags
}
