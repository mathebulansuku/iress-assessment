variable "bucket_name" {
  description = "S3 bucket name for the website"
  type        = string
}

variable "source_dir" {
  description = "Local directory to upload as website content"
  type        = string
}

variable "index_document" {
  description = "Index document"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "public_read" {
  description = "Whether to attach a public read bucket policy (requires public access not blocked at account)"
  type        = bool
  default     = false
}
