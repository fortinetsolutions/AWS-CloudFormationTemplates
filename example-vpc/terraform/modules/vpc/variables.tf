variable "access_key" {}
variable "secret_key" {}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
}

variable "aws_region" {
  description = "The AWS region to use"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
}

