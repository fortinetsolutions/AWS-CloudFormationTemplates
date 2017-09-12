variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "The AWS region to use"
  default = "us-west-2"
}

variable "acl" {
  description = "The S3 acl"
  default = "private"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable "fgt_instance_type" {
  description = "Initial Fortigate Instance Type"
  default = "m3.large"
}

variable "ftp_password" {
  description = "FTP password"
  default = "1hop2go"
}

variable "elb_target" {
  description = "ELB Health Check Target Port"
  default     = 80
}

variable "ilb_target" {
  description = "ILB Health Check Target Port"
  default     = 80
}

variable "asg1_min_size" {
  description = "Autoscale Group Min Size for Fortigate OnDemand instances"
  default     = 0
}

variable "asg1_max_size" {
  description = "Autoscale Group Max Size for Fortigate OnDemand instances"
  default     = 5
}

variable "asg1_desired_size" {
  description = "Autoscale Group Desired Size for Fortigate OnDemand instances"
  default     = 0
}

variable "asg2_min_size" {
  description = "Autoscale Group Min Size for Worker Node instances"
  default     = 0
}

variable "asg2_max_size" {
  description = "Autoscale Group Max Size for Worker Node instances"
  default     = 1
}

variable "asg2_desired_size" {
  description = "Autoscale Group Desired Size for Worker Node instances"
  default     = 0
}

variable "scaling_period" {
  description = "Autoscaling Scaling period in seconds"
  default     = 300
}

variable "threshold_high" {
  description = "Autoscaling Scaling threshold percentage high"
  default     = "80"
}

variable "threshold_low" {
  description = "Autoscaling Scaling threshold percentage low"
  default     = "40"
}

variable "key_name" {
  description = "Key name"
}
