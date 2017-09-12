variable "environment" {
  description = "The Tag Environment for the Worker Node"
  default = "stage"
}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "worker_node_instance_type" {
  description = "Initial Worker Node Instance Type"
  default = "t2.micro"
}

variable "public1_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 1"
}

variable "availability_zone" {
  description = "AZ for Worker Node"
}

variable "api_termination_protection" {
  description = "Boolean to enable api termination protection on Fortigate"
  default     = false
}

variable "enable_public_ips" {
  description = "Boolean to enable public IP on Worker Node"
  default     = false
}

variable "security_group_ids" {
  description = "Security Group used by Worker Node instance"
}


variable "asg2_min_size" {
  description = "Autoscale Group Min Size for Worker Node instances"
}

variable "asg2_max_size" {
  description = "Autoscale Group Max Size for Worker Node instances"
}

variable "asg2_desired_size" {
  description = "Autoscale Group Desired Size for Worker Node instances"
}
