module "lambda_ddbstreams_to_firehose" {
  source                    = "../../lambda-function"
  environment               = "${var.environment}"
  function_name             = "ddbstreams-to-kinesis"
  lambda_function_directory = "ddbstreams-to-kinesis"
  cloudwatch_alarm_action   = "${var.cloudwatch_alarm_action}"
  runtime                   = "go1.x"
  lambda_function_package   = "ddbstreams-to-kinesis.zip"
  memory_size               = 256
  timeout                   = "60"
  error_threshold           = 50
  function_handler          = "main_binary"

  lambda_function_env_vars = {
    kinesis_stream_prefix = "DYNAMODB-"
  }
}
