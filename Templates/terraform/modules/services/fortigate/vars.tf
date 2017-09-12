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

variable "acl" {
  description = "The S3 acl"
  default = "private"
}

variable "aws_fgtod_amis" {
  description = "The AMI ID for the On-Demand image"
}

variable "fgt_instance_type" {
  description = "Fortigate Instance Type"
}

variable "availability_zone" {
  description = "Availability Zone for this Fortigate Instance"
}

variable "api_termination_protection" {
  description = "If true, enables EC2 Instance Termination Protection"
  default     = false
}

variable "fortigate_instance_name" {
  description = "Instance name of Fortigate"
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
}

variable "private_subnet_id" {
  description = "Public Subnet ID"
}

variable "enable_public_ips" {
  description = "Boolean to Enable an Elastic IP on Fortigate"
}

variable "security_group_ids" {
  description = "Security Group used by Fortigate instances"
}

