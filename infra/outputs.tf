output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.file_storage_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.file_storage_bucket.arn
}