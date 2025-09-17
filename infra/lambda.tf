# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# aws IAM Policy for Lambda to access S3 and CloudWatch
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_s3_policy"
  description = "IAM policy for Lambda to access S3 and CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch logs
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },

      # Allow listing the bucket (required for GetObject existence checks)
      {
        Action = "s3:ListBucket"
        Effect = "Allow"
        Resource = aws_s3_bucket.file_storage_bucket.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "out/*",
              "count/*"
            ]
          }
        }
      },

      # Allow read/write objects in the bucket
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.file_storage_bucket.arn}/out/*",
          "${aws_s3_bucket.file_storage_bucket.arn}/count/*",
        ]
      }
    ]
  })
}


# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role      = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "word_count_lambda" {
  filename      = "lambda_function.zip"
  function_name = "word-counter-lambda"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  timeout = 60
  depends_on = [aws_iam_policy.lambda_policy]
}

# S3 Bucket notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.file_storage_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.word_count_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "out/"
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
    statement_id  = "AllowS3Invoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.word_count_lambda.function_name
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.file_storage_bucket.arn
}

