output "ddbstreams_to_kinesis_lambda_arn" {
  value       = "${module.lambda_ddbstreams_to_firehose.lambda_function_arn}"
  description = "DynamoDB table name"
}
