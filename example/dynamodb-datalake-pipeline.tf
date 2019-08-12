provider "aws" {
  region  = "ENTER_AWS_REGION_HERE"
  version = "~> 2.0"
}

module "datalake-pipeline-foundation" {
  source      = "../modules/datalake-pipeline-foundation"
  environment = "ENTER_ENVIRONMENT_HERE"
  region      = "ENTER_AWS_REGION_HERE"
}

module "datalake-pipeline-dynamodb-foundation" {
  source      = "../modules/datalake-pipeline-foundation/dynamodb"
  environment = "ENTER_ENVIRONMENT_HERE"
}

// pipeline example for 1 DynamoDB table
module "datalake-pipeline-dynamodb-table-ENTER_DYNAMODB_TABLE_NAME_HERE" {
  source                            = "../modules/datalake-pipeline-dynamodb"
  region                            = "ENTER_AWS_REGION_HERE"
  environment                       = "ENTER_ENVIRONMENT_HERE"
  ddb_streams_to_kinesis_lambda_arn = module.datalake-pipeline-dynamodb-foundation.ddbstreams_to_kinesis_lambda_arn
  bucket_firehose_output            = module.datalake-pipeline-foundation.firehouse_output_bucket_name
  bucket_data                       = module.datalake-pipeline-foundation.data_bucket_name
  glue_database_name                = module.datalake-pipeline-foundation.glue_database_name
  firehose_role_arn                 = module.datalake-pipeline-foundation.firehose_iam_role_arn

  dynamodb_stream_arn = "ENTER_DYNAMODB_STREAM_ARN_HERE"
  dynamodb_table_name = "ENTER_DYNAMODB_TABLE_NAME_HERE"
}


// add more tables by copying and modifying the module above ...