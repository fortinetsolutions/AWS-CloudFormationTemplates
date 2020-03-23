variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to use"
}
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}
variable "environment" {
  description = "The Tag Environment in the S3 tag"
}
