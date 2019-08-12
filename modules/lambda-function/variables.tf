variable "environment" {
  description = "Environment (e.g. prod, staging, etc...)"
  type        = string
}

variable "function_name" {
  description = "The (base) name of the lambda function"
}

variable "lambda_function_directory" {
  type        = string
  description = "The directory where the Lambda function code is located, relative to the lambdaFunctions/ directory"
}

variable "lambda_function_package" {
  default     = ""
  description = ".zip file containing the lambda deployment package"
}

variable "function_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "runtime" {
  default     = "nodejs6.10"
  description = "Lambda function runtime"
}

variable "concurrent_executions" {
  default     = -1
  description = "Max concurrent executions of the Lambda function, -1 = unlimited"
}

variable "lambda_function_env_vars" {
  type = map(string)

  default = {
    foo = "bar"
  }

  description = "Environment variables for the Lambda function"
}

variable "cloudwatch_alarm_action" {
  default     = ""
  description = "CloudWatch alarm action, e.g. SNS ARN which sends out email."
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  default     = 60
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  default     = 256
}

variable "error_threshold" {
  description = "Error threshold, Lambda invocation error rate above this will trigger a CloudWatch alarm."
  default     = 0.1
}

