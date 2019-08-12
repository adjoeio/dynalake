resource "aws_glue_catalog_database" "default" {
  name = var.environment
}

resource "aws_s3_bucket" "firehose_output" {
  bucket = "datalake-firehose-output-${var.environment}-${var.region}"

  lifecycle_rule {
    id      = "srcbackup"
    prefix  = "srcbackup/"
    enabled = true

    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "datalake-data-${var.environment}-${var.region}"
}

module "lambda_datalake_s3_flatten_firehose_datetime" {
  source                    = "../lambda-function"
  environment               = var.environment
  function_name             = "ds-s3-flatten-firehose-datetime"
  lambda_function_directory = "ds-s3-flatten-firehose-datetime"
  cloudwatch_alarm_action   = var.cloudwatch_alarm_action
  lambda_function_package   = "ds-s3-flatten-firehose-datetime.zip"
  runtime                   = "python3.7"
  memory_size               = 128
  timeout                   = "30"
  function_handler          = "ds-s3-flatten-firehose-datetime.handler"

  lambda_function_env_vars = {
    dst_bucket = aws_s3_bucket.data.id
  }
}

resource "aws_lambda_permission" "allow_firehose_output_bucket_datetime" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_datalake_s3_flatten_firehose_datetime.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.firehose_output.arn
}

resource "aws_s3_bucket_notification" "firehose_output_lambda" {
  bucket = aws_s3_bucket.firehose_output.id

  lambda_function {
    lambda_function_arn = module.lambda_datalake_s3_flatten_firehose_datetime.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_permission.allow_firehose_output_bucket_datetime]
}

resource "aws_iam_role" "firehose_role" {
  name = "${var.environment}-${var.region}-firehose-default-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "firehose_role" {
  name = "${var.environment}-${var.region}-firehose-default-role-policy"
  role = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_role.json
}

data "aws_iam_policy_document" "firehose_role" {
  statement {
    actions = [
      "glue:GetTableVersions",
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]

    resources = ["*"]

    effect = "Allow"
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.firehose_output.id}/",
      "arn:aws:s3:::${aws_s3_bucket.firehose_output.id}/*",
    ]

    effect = "Allow"
  }
}

