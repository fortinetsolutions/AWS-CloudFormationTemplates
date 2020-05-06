variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
    description = "Region for the DG VPC"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
}

variable "vpc_id" {
    description = "VPC ID for IGW"
}
