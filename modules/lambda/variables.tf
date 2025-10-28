variable "name" {
  description = "Lambda function name"
  type        = string
  default     = "hello-lambda"
}

variable "description" {
  description = "Function description"
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.11)"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.handler"
}

variable "source_dir" {
  description = "Local directory containing the Lambda source code"
  type        = string
  default     = null
}


variable "environment" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "create_role" {
  description = "Whether to create an IAM role for Lambda"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "Existing IAM role ARN to use (if create_role = false)"
  type        = string
  default     = null
}

variable "dataset_bucket" {
  description = "S3 bucket name containing the dataset JSON file"
  type        = string
  default     = null
}

variable "dataset_key" {
  description = "S3 object key for the dataset JSON file"
  type        = string
  default     = "cities.json"
}
