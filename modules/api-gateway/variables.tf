variable "name" {
  description = "HTTP API name"
  type        = string
  default     = "http-api"
}

variable "description" {
  description = "API description"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "protocol_type" {
  description = "API protocol type"
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "protocol_type must be one of: HTTP, WEBSOCKET."
  }
}

variable "create_default_stage" {
  description = "Whether to create a stage"
  type        = bool
  default     = true
}

variable "stage_name" {
  description = "Stage name (use $default for default stage)"
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Enable auto deploy for stage"
  type        = bool
  default     = true
}

variable "integrate_lambda" {
  description = "Whether to add a Lambda integration and route"
  type        = bool
  default     = false
}

variable "lambda_function_arn" {
  description = "Lambda function ARN to integrate"
  type        = string
  default     = null
}

variable "lambda_route_path" {
  description = "Route path for Lambda (e.g., /hello)"
  type        = string
  default     = "/hello"
}

variable "lambda_method" {
  description = "HTTP method for the Lambda route"
  type        = string
  default     = "GET"
}

 

// Custom domain variables removed per revert request

variable "create_default_catch_all" {
  description = "Create a $default catch-all route to the Lambda integration"
  type        = bool
  default     = true
}
