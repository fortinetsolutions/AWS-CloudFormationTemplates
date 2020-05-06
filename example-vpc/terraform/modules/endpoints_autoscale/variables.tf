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
variable "private1_subnet_id" {
  description = "Provide the ID for the first public subnet"
}
variable "private2_subnet_id" {
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
  description = "Target Group ARN of Load Balancer associate with autoscale group"
}
variable "userdata" {
  description = "Userdata path"
}