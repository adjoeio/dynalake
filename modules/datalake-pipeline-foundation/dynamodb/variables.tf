variable "environment" {
  type        = "string"
  description = "Environment (e.g. prod, staging, etc...)"
}

variable "cloudwatch_alarm_action" {
  default     = ""
  description = "CloudWatch alarm action, e.g. SNS ARN which sends out email."
}
