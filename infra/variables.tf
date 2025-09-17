variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "cost-effective-solution-bucket-122046"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}