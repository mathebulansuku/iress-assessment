variable "aws_region" {
  description = "AWS region for the provider"
  type        = string
  default     = "af-south-1"
}

variable "tf_state_bucket_name" {
  description = "Name of the S3 bucket to store Terraform state"
  type        = string
  default     = "iress-assessment-tf-state-2025"
}

variable "tf_lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "iress-assessment-tf-locks"
}

variable "tf_state_versioning_enabled" {
  description = "Enable versioning on the Terraform state S3 bucket"
  type        = bool
  default     = true
}

variable "tf_state_sse_algorithm" {
  description = "SSE algorithm for the Terraform state S3 bucket"
  type        = string
  default     = "AES256"
}

variable "random_suffix_byte_length" {
  description = "Byte length for random suffix generation"
  type        = number
  default     = 3
}

variable "dataset_bucket_prefix" {
  description = "Prefix for the dataset S3 bucket name"
  type        = string
  default     = "iress-assessment-dataset"
}

variable "dataset_source_dir" {
  description = "Local directory containing dataset JSON files"
  type        = string
  default     = null
}

variable "project" {
  description = "Project name tag"
  type        = string
  default     = "iress-assessment"
}

variable "environment" {
  description = "Environment name tag"
  type        = string
  default     = "dev"
}

variable "extra_tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}

variable "frontend_bucket_prefix" {
  description = "Prefix for the frontend website S3 bucket name"
  type        = string
  default     = "iress-assessment-frontend"
}

variable "frontend_source_dir" {
  description = "Local directory containing frontend static files"
  type        = string
  default     = null
}

variable "lambda_name" {
  description = "Lambda function name"
  type        = string
  default     = "iress-hello"
}

variable "lambda_dataset_key" {
  description = "Dataset object key for the Lambda function"
  type        = string
  default     = "cities.json"
}

variable "api_name" {
  description = "API Gateway name"
  type        = string
  default     = "iress-http-api"
}

variable "api_protocol_type" {
  description = "Protocol type for API Gateway"
  type        = string
  default     = "HTTP"
}

variable "api_create_default_stage" {
  description = "Create default stage for the API"
  type        = bool
  default     = true
}

variable "api_stage_name" {
  description = "API stage name"
  type        = string
  default     = "$default"
}

variable "api_auto_deploy" {
  description = "Enable auto deploy on the API stage"
  type        = bool
  default     = true
}

variable "api_integrate_lambda" {
  description = "Integrate the Lambda function with API Gateway"
  type        = bool
  default     = true
}

variable "api_lambda_route_path" {
  description = "Route path for Lambda integration"
  type        = string
  default     = "/hello"
}

variable "api_lambda_method" {
  description = "HTTP method for Lambda route"
  type        = string
  default     = "GET"
}
