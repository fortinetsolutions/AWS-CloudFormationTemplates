variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
  description = "Provide the region to use"
}
variable "vpc_id" {
  description = "Provide the VPC ID for the instance"
}
variable "name" {
  description = "Security Group Name suffix"
}
variable "security_group_dmz_id" {
  description = "Security Group for DMZ ENI"
}
variable "security_group_ws_id" {
  description = "Security Group for WS ENI"
}
variable "security_group_trust_id" {
  description = "Security Group for TRUST ENI"
}
variable "ingress_from_port" {
  description = "Ingress from port for security group"
}
variable "ingress_to_port" {
  description = "Ingress to port for security group"
}
variable "ingress_protocol" {
  description = "Ingress protocol for security group"
}
variable "egress_from_port" {
  description = "Egress from port for security group"
}
variable "egress_to_port" {
  description = "Egress to port for security group"
}
variable "egress_protocol" {
  description = "Egress protocol for security group"
}
variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}
variable "environment" {
  description = "The Tag Environment in the S3 tag"
}
variable "ingress_cidr_for_access" {
  description = "CIDR to use for security group access"
}
variable "egress_cidr_for_access" {
  description = "CIDR to use for security group access"
}


