variable "bucket_name" {
  description = "Name of the S3 bucket to store dataset JSON files"
  type        = string
}

variable "source_dir" {
  description = "Local directory containing JSON files to upload"
  type        = string
}

variable "key_prefix" {
  description = "Optional key prefix in the bucket for uploaded files"
  type        = string
  default     = ""
}

variable "versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if not empty"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

