variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to use"
}
variable "ami_id" {
  description = "AMI ID for the new instance"
}
variable "vpc_id" {
  description = "Provide the VPC ID for the instance"
}
variable "subnet_id" {
  description = "Provide the ID for the subnet"
}
variable "keypair" {
  description = "Provide a keypair for accessing the FortiGate instance"
}
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}
variable "environment" {
  description = "The Tag Environment in the S3 tag"
}
variable "cidr_for_access" {
  description = "CIDR to use for security group access"
}
variable "instance_type" {
  description = "Instance type for endpoint"
}
variable "instance_count" {
  description = "Instance count"
}
variable "public_ip" {
  description = "Boolean - Associate Public IP address"
  default = false
}
variable "security_group" {
  description = "Security Group for the instance"
}

