variable "aws_region" {
  type        = string
  description = "The primary AWS target deployment region for the core pipeline"
  default     = "ap-southeast-3" # Jakarta
}

variable "bucket_name" {
  type = string
}

variable "youtube_api_key" {
  type      = string
  sensitive = true
}

variable "target_comment_count" {
  type    = number
  default = 10
}