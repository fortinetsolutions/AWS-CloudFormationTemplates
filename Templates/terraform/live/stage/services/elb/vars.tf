variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "public1_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 1"
}

variable "public2_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 2"
  default = "None"
}


variable "private1_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 1"
}

variable "private2_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 2"
  default = "None"
}

variable "availability_zone_1" {
  description = "AZ for first set of Fortigates"
}

variable "availability_zone_2" {
  description = "AZ for second set of Fortigates"
  default     = "None"
}

variable "elb_target" {
  description = "ELB Health Check Target Port"
  default     = 80
}

variable "ilb_target" {
  description = "ILB Health Check Target Port"
  default     = 80
}

variable "log_bucket" {
  description = "S3 bucket for logs"
}
