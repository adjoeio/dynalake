resource "aws_glue_catalog_database" "default" {
  name = var.environment
}

resource "aws_s3_bucket" "data" {
  bucket = "datalake-data-${var.environment}-${var.region}"
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
      "arn:aws:s3:::${aws_s3_bucket.data.id}/",
      "arn:aws:s3:::${aws_s3_bucket.data.id}/*",
    ]

    effect = "Allow"
  }
}

