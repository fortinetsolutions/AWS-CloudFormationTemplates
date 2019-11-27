variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment S3 tag"
}

variable "bucket" {
  description = "The name of the S3 bucket"
}

variable "acl" {
  description = "The S3 acl"
}
