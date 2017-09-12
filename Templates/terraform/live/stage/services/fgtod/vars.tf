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

variable "fgt_instance_type" {
  description = "Initial Fortigate Instance Type"
  default = "c3.8xlarge"
}

variable "sqs_target_arn" {
  description = "SQS ARN for Autoscale Notifications"
}

variable "public1_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 1"
}

variable "private1_subnet_id" {
  description = "Subnet ID of Private Subnet in AZ 1"
}

variable "public2_subnet_id" {
  description = "Subnet ID of Public Subnet in AZ 2"
  default = "None"
}

variable "private2_subnet_id" {
  description = "Subnet ID of Private Subnet in AZ 2"
  default = "None"
}

variable "availability_zone_1" {
  description = "AZ for first set of Fortigates"
}

variable "availability_zone_2" {
  description = "AZ for second set of Fortigates"
  default     = "None"
}

variable "enable_public_ips" {
  description = "Boolean to enable public IP on Fortigate"
  default     = false
}

variable "api_termination_protection" {
  description = "Boolean to enable api termination protection on Fortigate"
  default     = false
}
variable "security_group_ids" {
  description = "Security Group used by Fortigate instances"
}


variable "asg1_min_size" {
  description = "Autoscale Group Min Size for Fortigate OnDemand instances"
}

variable "asg1_max_size" {
  description = "Autoscale Group Max Size for Fortigate OnDemand instances"
}

variable "asg1_desired_size" {
  description = "Autoscale Group Desired Size for Fortigate OnDemand instances"
}

variable "scaling_period" {
  description = "Autoscaling Scaling period in seconds"
}

variable "threshold_high" {
  description = "Autoscaling Scaling threshold percentage high"
}

variable "threshold_low" {
  description = "Autoscaling Scaling threshold percentage low"
}
