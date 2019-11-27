variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-east-1"
}

variable "acl" {
  description = "The S3 acl"
  default = "private"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable "fgt_instance_type" {
  description = "Initial Fortigate Instance Type"
  default = "m3.large"
}

variable "elb_target" {
  description = "ELB Health Check Target Port"
  default     = 80
}

variable "ilb_target" {
  description = "ILB Health Check Target Port"
  default     = 80
}

variable "asg1_min_size" {
  description = "Autoscale Group Min Size for Fortigate BYOL instances"
  default     = 0
}

variable "asg1_max_size" {
  description = "Autoscale Group Max Size for Fortigate BYOL instances"
  default     = 5
}

variable "asg1_desired_size" {
  description = "Autoscale Group Desired Size for Fortigate BYOL instances"
  default     = 0
}

variable "asg2_min_size" {
  description = "Autoscale Group Min Size for PAYGO instances"
  default     = 0
}

variable "asg2_max_size" {
  description = "Autoscale Group Max Size for PAYGO instances"
  default     = 1
}

variable "asg2_desired_size" {
  description = "Autoscale Group Desired Size for PAYGO instances"
  default     = 0
}

variable "scaling_period" {
  description = "Autoscaling Scaling period in seconds"
  default     = 300
}

variable "threshold_high" {
  description = "Autoscaling Scaling threshold percentage high"
  default     = "80"
}

variable "threshold_low" {
  description = "Autoscaling Scaling threshold percentage low"
  default     = "40"
}

variable "key_name" {
  description = "Key name"
  default = ""
}

variable "lambda_name" {
  default = "autoscale_lambda_function"
}

variable "lambda_description" {
  default = "Lambda function to manage Mixed License Fortigate Autoscale Groups"
}

variable "lambda_handler" {
  default = "lambda_handler.handler"
}

variable "runtime" {
  default = "python2.7"
}

variable "package_path" {
  description = "The path to the function's deployment package within the local filesystem."
}

variable "tag_name_prefix" {
  description = "Tags to prefix to autoscale resources"
}