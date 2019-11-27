variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to deploy the VPC in"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment NLB tag"
}

variable "lambda_invoke_arn" {
  description = "The Lambda function ARN to be used by the API Gateway"
}
variable "lambda_function_name" {
  description = "lambda function name that API gateway should invoke"
}
