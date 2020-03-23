variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to deploy the VPC in"
}
variable "sns_topic" {
  description = "The name of the SNS topic that S3 Dirty will publish to on updates"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment SNS tag"
}

variable "asg_name" {
  description = "Tag to differentiate multiple autoscale groups within customer-prefix combinations"
}

variable "notification_url" {
  description = "Notification URL for SNS message delivery"
}