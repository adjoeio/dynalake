locals {
  full_function_name     = "${var.environment}-${var.function_name}"
  function_packaged_path = "${path.module}/lambdaFunctions/${var.lambda_function_directory}/${var.lambda_function_package}"
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role-${var.environment}-${var.function_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "lambda_iam_role" {
  name = "lambda_execution_policy-${var.environment}-${var.function_name}"
  role = aws_iam_role.lambda_execution_role.id

  policy = file(
    "${path.module}/lambdaFunctions/${var.lambda_function_directory}/policy/lambda_policy.json",
  )
}

resource "aws_lambda_function" "lambda_packaged" {
  function_name = local.full_function_name
  role = aws_iam_role.lambda_execution_role.arn
  handler = var.function_handler
  filename = "${path.module}/lambdaFunctions/${var.lambda_function_directory}/${var.lambda_function_package}"
  source_code_hash = filebase64sha256(local.function_packaged_path)
  timeout = var.timeout
  memory_size = var.memory_size
  runtime = var.runtime

  environment {
    variables = var.lambda_function_env_vars
  }
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name = "${var.environment}-lambda-${var.function_name}-too-many-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "1"
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Average"
  threshold = var.error_threshold
  alarm_description = "This alarm monitors the Lambda error rate"
  alarm_actions = var.cloudwatch_alarm_action == "" ? [] : [var.cloudwatch_alarm_action]
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = local.full_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  alarm_name = "${var.environment}-lambda-${var.function_name}-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "1"
  metric_name = "Throttles"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Average"
  threshold = "0"
  alarm_description = "This alarm monitors if the Lambda function got throttled"
  alarm_actions = var.cloudwatch_alarm_action == "" ? [] : [var.cloudwatch_alarm_action]
  treat_missing_data = "notBreaching"

  dimensions = {
    FunctionName = local.full_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  alarm_name = "${var.environment}-lambda-${var.function_name}-long-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = "300"
  statistic = "Average"
  threshold = "30000"
  alarm_description = "Lambda function took longer than 30 seconds to complete."
  alarm_actions = var.cloudwatch_alarm_action == "" ? [] : [var.cloudwatch_alarm_action]

  dimensions = {
    FunctionName = local.full_function_name
  }
}

