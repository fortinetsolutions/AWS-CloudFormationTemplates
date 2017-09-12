variable "environment" {
  description = "The Tag Environment in the Worker Node tag"
  default = "stage"
}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "aws_wn_amis" {
  description = "The AMI ID for the Worker Node image"
}

variable "worker_node_instance_type" {
  description = "Worker Node Instance Type"
}

variable "availability_zone" {
  description = "Availability Zone for Worker Node Instance"
}

variable "worker_node_instance_name" {
  description = "Instance name of Worker Node"
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
}

variable "api_termination_protection" {
  description = "Boolean to enable api termination protection on Worker Node"
  default     = false
}

variable "enable_public_ips" {
  description = "Boolean to Enable an Elastic IP on Worker Node"
}

variable "security_group_ids" {
  description = "Security Group used by Worker Node instances"
}

variable "instance_profile" {
  description = "IAM Instance Profile for Worker Node"
}

variable "key_name" {
  description = "Key name"
}


