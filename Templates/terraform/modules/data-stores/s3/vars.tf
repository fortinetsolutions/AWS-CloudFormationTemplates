variable "aws_region" {
  description = "The AWS region to use"
}

variable "bucket" {
  description = "The name of the S3 bucket"
}

variable "acl" {
  description = "The S3 acl"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}
