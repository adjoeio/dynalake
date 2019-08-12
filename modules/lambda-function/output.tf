output "lambda_function_arn" {
  value = aws_lambda_function.lambda_packaged.arn
}

output "lambda_function_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

