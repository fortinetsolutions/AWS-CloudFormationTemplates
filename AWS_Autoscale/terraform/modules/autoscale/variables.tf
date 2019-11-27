variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to deploy the VPC in"
}
variable "ami_id" {
  description = "AMI ID of instances in the autoscale group"
}
variable "vpc_id" {
  description = "The VPC Id of the newly created VPC."
}
variable "instance_type" {
  description = "Instance type to launch from the autoscale group"
}
variable "public_subnet1_id" {
  description = "Provide the ID for the first public subnet"
}
variable "public_subnet2_id" {
  description = "Provide the ID for the first public subnet"
}
variable "private_subnet1_id" {
  description = "Provide the ID for the first public subnet"
}
variable "private_subnet2_id" {
  description = "Provide the ID for the first public subnet"
}
variable "security_group" {
  description = "Security Group for autoscale instances"
}
variable "key_name" {
  description = "Keyname to use for the autoscale instance"
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
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}
variable "environment" {
  description = "The Tag Environment NLB tag"
}
variable "target_group_arns" {
  type = "list"
}
variable "topic_arn" {
  description = "Topic ARN for Lifecycle Notifications"
  default     = ""
}
variable "userdata" {
  description = "Userdata path"
}
variable "license" {
  description = "Type of licensing"
}
variable "asg_name" {
  description = "Autoscale group tag to allow multiple autoscale groups"
}
variable "s3_license_bucket" {
  description = "S3 Bucket that contains BYOL License Files"
}
variable monitored_asg_name {
  description = "ASG to be monitored if not the one being created"
}