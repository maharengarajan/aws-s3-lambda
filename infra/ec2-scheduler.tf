# IAM Role for EC2 scheduler Lambda
resource "aws_iam_role" "ec2_scheduler_lambda_role" {
  name = "ec2-scheduler-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for EC2 scheduler Lambda
resource "aws_iam_role_policy" "ec2_scheduler_lambda_policy" {
  name = "ec2-scheduler-lambda-policy"
  role = aws_iam_role.ec2_scheduler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Lambda function for EC2 scheduler
resource "aws_lambda_function" "ec2_scheduler_lambda" {
  filename      = "ec2_scheduler_lambda.zip"
  function_name = "ec2-scheduler-lambda"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.ec2_scheduler_lambda_role.arn
  timeout = 300
  depends_on = [aws_iam_role_policy.ec2_scheduler_lambda_policy]
}

# CloudWatch Event for EC2 stop (6 PM daily)
resource "aws_cloudwatch_event_rule" "ec2_stop_rule" {
  name                = "ec2-stop-rule"
  description         = "Rule to stop EC2 instances at 6 PM IST daily"
  schedule_expression = "cron(0 18 ? * * *)"
}

# CloudWatch Event for EC2 start (9 AM daily)
resource "aws_cloudwatch_event_rule" "ec2_start_rule" {
  name                = "ec2-start-rule"
  description         = "Rule to start EC2 instances at 8 AM IST daily"
  schedule_expression = "cron(0 9 ? * * *)"
}

# CloudWatch Event Target for EC2 stop
resource "aws_cloudwatch_event_target" "ec2_stop_target" {
  rule         = aws_cloudwatch_event_rule.ec2_stop_rule.name
  arn          = aws_lambda_function.ec2_scheduler_lambda.arn
  target_id    = "ec2-stop-target"
  input        = jsonencode({ action = "stop" })
}

# CloudWatch Event Target for EC2 start
resource "aws_cloudwatch_event_target" "ec2_start_target" {
  rule         = aws_cloudwatch_event_rule.ec2_start_rule.name
  arn          = aws_lambda_function.ec2_scheduler_lambda.arn
  target_id    = "ec2-start-target"
  input        = jsonencode({ action = "start" })
}

# Permission for CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda_stop" {
  statement_id  = "AllowExecutionFromCloudWatchStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_stop_rule.arn
}

# Permission for CloudWatch to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda_start" {
  statement_id  = "AllowExecutionFromCloudWatchStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_start_rule.arn
}