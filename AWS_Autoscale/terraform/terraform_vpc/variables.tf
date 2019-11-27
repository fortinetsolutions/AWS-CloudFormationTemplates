variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
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
    description = "CIDR for the Public Subnet 1"
}

variable "private_subnet_cidr_1" {
    description = "CIDR for the Private Subnet 1"
}

variable "public_subnet_cidr_2" {
    description = "CIDR for the Public Subnet 2"
}

variable "private_subnet_cidr_2" {
    description = "CIDR for the Private Subnet 2"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

