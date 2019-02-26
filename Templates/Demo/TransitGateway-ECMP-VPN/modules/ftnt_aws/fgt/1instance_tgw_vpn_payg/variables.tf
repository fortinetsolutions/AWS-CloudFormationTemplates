variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to use"
  default = "us-east-1"
}
variable "availability_zone" {
  description = "Provide the availability zone to create resources in"
  default = "us-east-1a"
}
variable "vpc_id" {
  description = "Provide ID for the VPC"
  default = "vpc-11111111111111111111"
}
variable "vpc_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "10.0.0.0/16"
}
variable "public_subnet_id" {
  description = "Provide the ID for the public subnet"
  default = "subnet-1111111111111111111"
}
variable "ami" {
  description = "Provide an AMI for the FortiGate instance"
  default = ""
}
variable "instance_type" {
  description = "Provide the instance type for the FortiGate instance"
  default = "c5.large"
}
variable "keypair" {
  description = "Provide a keypair for accessing the FortiGate instance"
  default = "kp-poc-common"
}
variable "cidr_for_access" {
  description = "Provide a network CIDR for accessing the FortiGate instance"
  default = "0.0.0.0/0"
}
variable "license_type" {
  description = "Provide the license type for the FortiGate instance, byol or ond"
  default = "ond"
}
variable "bgp_asn" {
  description = "Provide the BGP ASN for the FortiGate instance"
  default = "65101"
}
variable "loopback_ip" {
  description = "Provide an IP address for the loopback interface"
  default = "100.64.0.1"
}
variable "target_group_arn" {
  description = "Provide a target group ARN to register the instance to"
  default = ""
}
variable "transit_gateway_id" {
  description = "Provide the id of the transit gateway"
  default = "tgw..."
}
variable "tag_name_prefix" {
  description = "Provide a tag prefix value that that will be used in the name tag for all resources"
  default = "stack-1"
}
variable "tag_name_unique" {
  description = "Provide a unique tag prefix value that will be used in the name tag for each modules resources"
  default = ""
}