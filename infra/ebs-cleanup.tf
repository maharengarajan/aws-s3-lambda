# IAM Role for EBS Cleanup Lambda Function
resource "aws_iam_role" "ebs_cleanup_lambda_role" {
  name = "ebs-cleanup-lambda-role"
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

# IAM Policy for EBS Cleanup Lambda Function
resource "aws_iam_role_policy" "ebs_cleanup_lambda_policy" {
  name = "ebs-cleanup-lambda-policy"
  role = aws_iam_role.ebs_cleanup_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DeleteVolume",
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Lambda Function for EBS Cleanup
resource "aws_lambda_function" "ebs_cleanup_lambda" {
  filename      = "ebs_cleanup_lambda.zip"
  function_name = "ebs-cleanup-lambda"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.ebs_cleanup_lambda_role.arn
  timeout = 900
  depends_on = [aws_iam_role_policy.ebs_cleanup_lambda_policy]
}

# CloudWatch Event Rule to trigger Lambda every week
resource "aws_cloudwatch_event_rule" "ebs_cleanup_rule" {
  name                = "ebs-cleanup-rule"
  description         = "Trigger EBS cleanup Lambda every week"
  schedule_expression = "cron(0 0 ? * SUN *)" # Every Sunday at midnight
}

# Cloudwatch Event Target to link the rule to the Lambda function
resource "aws_cloudwatch_event_target" "ebs_cleanup_target" {
  rule         = aws_cloudwatch_event_rule.ebs_cleanup_rule.name
  arn          = aws_lambda_function.ebs_cleanup_lambda.arn
  target_id    = "ebs-cleanup-target"
}

# Permission for CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchEBS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_cleanup_lambda.function_name
  principal     = "events.amazonaws.com"    
  source_arn    = aws_cloudwatch_event_rule.ebs_cleanup_rule.arn
}
