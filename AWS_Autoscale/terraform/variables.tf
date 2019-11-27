variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-east-1"
}
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment to differentiate prod/test/dev"
}
variable "availability_zone1" {
  description = "Availability Zone 1 for dual AZ VPC"
}

variable "availability_zone2" {
  description = "Availability Zone 2 for dual AZ VPC"
}
variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
}

variable "public_subnet_cidr_1" {
    description = "CIDR for the Public Subnet"
}

variable "private_subnet_cidr_1" {
    description = "CIDR for the Private Subnet"
}

variable "public_subnet_cidr_2" {
    description = "CIDR for the Public Subnet"
}

variable "private_subnet_cidr_2" {
    description = "CIDR for the Private Subnet"
}
variable "keypair" {
  description = "Keypair for instances that support keypairs"
}
variable "max_size" {
  description = "Max autoscale group size"
}
variable "min_size" {
  description = "Min autoscale group size"
}
variable "desired" {
  description = "Desired autoscale group size"
}
variable "max_size-paygo" {
  description = "Max autoscale group size"
}
variable "min_size-paygo" {
  description = "Min autoscale group size"
}
variable "desired-paygo" {
  description = "Desired autoscale group size"
}
variable "max_size-byol" {
  description = "Max autoscale group size"
}
variable "min_size-byol" {
  description = "Min autoscale group size"
}
variable "desired-byol" {
  description = "Desired autoscale group size"
}
variable "cidr_for_access" {
  description = "CIDR to use for security group access"
}
variable "endpoint_instance_type" {
  description = "Instance type for endpoints in the private subnets"
}
variable "fortigate_instance_type" {
  description = "Instance type for fortigates in the private subnets"
}
variable "public_ip" {
  description = "Boolean to determine if endpoints should associate a public ip"
}
variable "sns_topic" {
  description = "SNS Topic"
}
variable "api_gateway_url" {
  description = "API Gateway URL"
}
variable "s3_license_bucket" {
  description = "S3 Bucket that contains BYOL License Files"
}
variable "acl" {
  description = "The S3 acl"
}

