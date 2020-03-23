variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to deploy the VPC in"
}
variable "vpc_id" {
  description = "The VPC Id of the newly created VPC."
}

variable "subnet1_id" {
  description = "Provide the ID for the first public subnet"
}
variable "subnet2_id" {
  description = "Provide the ID for the first public subnet"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment NLB tag"
}