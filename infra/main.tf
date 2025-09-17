terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket for file storage
resource "aws_s3_bucket" "file_storage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "file_storage_bucket_versioning" {
  bucket = aws_s3_bucket.file_storage_bucket.id
  versioning_configuration {
    status = "Enabled"
  }  
}

# create folders in the bucket
resource "aws_s3_object" "out_folder" {
  bucket = aws_s3_bucket.file_storage_bucket.id
  key    = "out/"
}

resource "aws_s3_object" "count_folder" {
  bucket = aws_s3_bucket.file_storage_bucket.id
  key    = "count/"
}

