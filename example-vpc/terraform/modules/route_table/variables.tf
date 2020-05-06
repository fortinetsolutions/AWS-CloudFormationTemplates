variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable "vpc_id" {
  description = "Route Table VPC ID"
}

variable "eni_route" {
  description = "Boolean to Create an ENI Route"
}

variable "gateway_route" {
  description = "Boolean to Create an Gateway Route"
}

variable "eni_id" {
  description = "Network Interface to use for ENI Route"
}

variable "igw_id" {
  description = "Network Interface to use for ENI Route"
}

variable "subnet_id" {
  description = "Subnet Association for Route Table"
}

variable "route_description" {
  description = "Route Description for Tag"
}