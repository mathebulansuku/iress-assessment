terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.18.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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

  # lifecycle {
  #   prevent_destroy = true
  # }
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

  # lifecycle {
  #   prevent_destroy = true
  # }
}


resource "random_id" "dataset_suffix" {
  byte_length = 3
}

module "dataset_bucket" {
  source      = "./modules/s3-data"
  bucket_name = "iress-assessment-dataset-${random_id.dataset_suffix.hex}"
  source_dir  = "${path.root}/dataset"
  tags = {
    Project = "iress-assessment"
    Env     = "dev"
  }
}

module "lambda" {
  source         = "./modules/lambda"
  name           = "iress-hello"
  dataset_bucket = module.dataset_bucket.bucket_name
  dataset_key    = "cities.json"
  # Optional: customize runtime/handler or source_content
  # runtime = "python3.11"
  # handler = "index.handler"
}

module "api_gateway" {
  source        = "./modules/api-gateway"
  name          = "iress-http-api"
  protocol_type        = "HTTP"
  create_default_stage = true
  stage_name           = "$default"
  auto_deploy          = true

  # Integrate Lambda at /hello with GET
  integrate_lambda    = true
  lambda_function_arn = module.lambda.arn
  lambda_route_path   = "/hello"
  lambda_method       = "GET"

  # HTTP API auto-deploy handles deployments; no mock needed

  tags = {
    Project = "iress-assessment"
    Env     = "dev"
  }
}
