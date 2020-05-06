variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "aws_fgtbyol_ami" {
  description = "The AMI ID for the On-Demand image"
}

variable "keypair" {
  description = "Key Pair to use for the instance"
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

variable "public_ip_address" {
  description = "Public ENI IP address"
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
}

variable "private_ip_address" {
  description = "Private ENI IP address"
}

variable "enable_public_ips" {
  description = "Boolean to Enable an Elastic IP on Fortigate"
}

variable "security_group_public_id" {
  description = "Security Group used by  ENI"
}

variable "security_group_private_id" {
  description = "Security Group used by Private ENI"
}

variable "acl" {
  description = "The S3 acl"
  default = "private"
}

variable "fgt_byol_license" {
  description = "Fortigate BYOL License File"
}

variable "fgt_password_parameter_name" {
  description = "Password Parameter Name in SSM for default Fortigate Password"
}
