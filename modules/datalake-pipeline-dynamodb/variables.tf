variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. prod, staging, etc...)"
}

variable "cloudwatch_alarm_action" {
  default     = ""
  description = "CloudWatch alarm action, e.g. SNS ARN which sends out email."
}

variable "firehose_role_arn" {
  type        = string
  description = "IAM role ARN which Firehose will use"
}

variable "firehose_buffer_size" {
  default     = 32
  description = "Firehose Buffer size in MB"
}

variable "firehose_buffer_interval" {
  default     = 300
  description = "Firehose Buffer interval in seconds"
}

variable "ddb_streams_to_kinesis_lambda_arn" {
  type        = string
  description = "ARN of the lambda function that puts the records from DynamoDB streams to Firehose."
}

variable "ddb_streams_starting_position" {
  default     = "LATEST"
  description = "DynamoDB streams starting position (LATEST or TRIM_HORIZON)"
}

variable "glue_database_name" {
  type        = string
  description = "Name of the AWS Glue database"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the source DynamoDB table."
}

variable "dynamodb_stream_arn" {
  type        = string
  description = "ARN for the stream of the source DynamoDB table."
}

variable "kinesis_shard_count" {
  default     = 1
  description = "Amount of shards for the Kinesis stream"
}

variable "kinesis_retention_period" {
  default     = 24
  description = "Kinesis retention period in hours"
}

variable "bucket_data" {
  type        = string
  description = "S3 bucket where to the data will end up"
}

