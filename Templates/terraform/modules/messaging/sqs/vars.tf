variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "queue_name" {
  description = "The name of the SQS Queue"
}

variable "receive_wait_time_seconds" {
  description = "The number of seconds to wait for a queue delivery"
}
