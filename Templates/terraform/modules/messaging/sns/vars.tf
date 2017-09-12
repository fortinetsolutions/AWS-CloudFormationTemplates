variable "aws_region" {
  description = "The AWS region to use"
}

variable "sns_topic" {
  description = "The name of the SNS topic that S3 Dirty will publish to on updates"
}

variable "sns_subscription" {
  description = "The subscription name used by the Lambda worker allocation function"
}