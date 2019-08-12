output "firehouse_output_bucket_name" {
  value       = aws_s3_bucket.firehose_output.id
  description = "Firehose output/Intermediate S3 bucket name"
}

output "data_bucket_name" {
  value       = aws_s3_bucket.data.id
  description = "Data/Final bucket name"
}

output "glue_database_name" {
  value = aws_glue_catalog_database.default.name
}

output "firehose_iam_role_arn" {
  value = aws_iam_role.firehose_role.arn
}

