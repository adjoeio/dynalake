
resource "aws_lambda_event_source_mapping" "ddbstreams_to_lambda" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = var.ddb_streams_to_kinesis_lambda_arn
  starting_position = var.ddb_streams_starting_position
  batch_size        = 1000
}

data "aws_iam_role" "glue" {
  name = "AWSGlueServiceRole-DefaultRole"
}

resource "aws_glue_crawler" "dynamodb_json" {
  database_name = var.glue_database_name
  name          = "${var.environment}-dynamodb-json-${var.dynamodb_table_name}"
  role          = data.aws_iam_role.glue.arn
  table_prefix  = "dynamodb_"
  schedule      = "cron(0/10 * * * ? *)"

  s3_target {
    path = "s3://${var.bucket_data}/dynamodb/json/${var.dynamodb_table_name}/"
  }
}

resource "aws_kinesis_stream" "ddbstreams_json" {
  name             = "DYNAMODB-${var.dynamodb_table_name}"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period
}

resource "aws_cloudwatch_metric_alarm" "kinesis_throughputlimit_write" {
  alarm_name          = "kinesis-ddb-${var.dynamodb_table_name}-write-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This alarm monitors if Kinesis write operations got throttled."
  alarm_actions       = var.cloudwatch_alarm_action == "" ? [] : [var.cloudwatch_alarm_action]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = aws_kinesis_stream.ddbstreams_json.name
  }
}

resource "aws_cloudwatch_metric_alarm" "kinesis_throughputlimit_read" {
  alarm_name          = "kinesis-ddb-${var.dynamodb_table_name}-readlimit-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This alarm monitors if Kinesis read operations got throttled."
  alarm_actions       = var.cloudwatch_alarm_action == "" ? [] : [var.cloudwatch_alarm_action]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = aws_kinesis_stream.ddbstreams_json.name
  }
}

resource "aws_kinesis_firehose_delivery_stream" "ddbstreams_to_s3_json" {
  name        = "dynamodb-${var.dynamodb_table_name}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.ddbstreams_json.arn
    role_arn           = var.firehose_role_arn
  }

  extended_s3_configuration {
    role_arn            = var.firehose_role_arn
    bucket_arn          = "arn:aws:s3:::${var.bucket_data}"
    buffer_size         = var.firehose_buffer_size
    buffer_interval     = var.firehose_buffer_interval
    prefix              = "dynamodb/json/${var.dynamodb_table_name}/dt=!{timestamp:yyyyMMdd}/"
    error_output_prefix = "dynamodb-errors/!{firehose:error-output-type}/${var.dynamodb_table_name}/dt=!{timestamp:yyyyMMdd}/"
    compression_format  = "GZIP"
  }
}

