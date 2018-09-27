variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to deploy the VPC in"
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
  default = "192.168.0.0/16"
}
variable "public_subnet_id" {
  description = "Provide the ID for the public subnet"
  default = "subnet-1111111111111111111"
}
variable "private_subnet_id" {
  description = "Provide the ID for the private subnet"
  default = "subnet-1111111111111111111"
}
variable "hasync_subnet_id" {
  description = "Provide the ID for the hasync subnet"
  default = "subnet-1111111111111111111"
}
variable "hamgmt_subnet_id" {
  description = "Provide the ID for the hamgmt subnet"
  default = "subnet-1111111111111111111"
}
variable "fgt1_eni0_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt1 eni0 (IP from public_subnet)"
  default = "192.168.1.11/24"
}
variable "fgt1_eni0_ip2_cidr" {
  description = "Provide the secondary IP in CIDR form for fgt1 eni0 (IP from public_subnet)"
  default = "192.168.1.13/24"
}
variable "fgt1_eni1_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt1 eni1 (IP from private_subnet)"
  default = "192.168.2.11/24"
}
variable "fgt1_eni1_ip2_cidr" {
  description = "Provide the secondary IP in CIDR form for fgt1 eni1 (IP from private_subnet)"
  default = "192.168.2.13/24"
}
variable "fgt1_eni2_ip1_cidr" {
  description = "Provide the primary IP for in CIDR form fgt1 eni2 (IP from hasync_subnet)"
  default = "192.168.3.11/24"
}
variable "fgt1_eni3_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt1 eni3 (IP from hamgmt_subnet)"
  default = "192.168.4.11/24"
}
variable "fgt2_eni0_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt2 eni0 (IP from public_subnet)"
  default = "192.168.1.12/24"
}
variable "fgt2_eni1_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt2 eni1 (IP from private_subnet)"
  default = "192.168.2.12/24"
}
variable "fgt2_eni2_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt2 eni2 (IP from hasync_subnet)"
  default = "192.168.3.12/24"
}
variable "fgt2_eni3_ip1_cidr" {
  description = "Provide the primary IP in CIDR form for fgt2 eni3 (IP from hamgmt_subnet)"
  default = "192.168.4.12/24"
}
variable "public_subnet_intrinsic_router_ip" {
  description = "Provide the IP address of the AWS intrinsic router (First IP from public_subnet)"
  default = "192.168.1.1"
}
variable "public_subnet_intrinsic_dns_ip" {
  description = "Provide the IP address of the AWS intrinsic dns server (Second IP from public_subnet)"
  default = "192.168.1.2"
}
variable "private_subnet_intrinsic_router_ip" {
  description = "Provide the IP address of the AWS intrinsic router (First IP from private_subnet)"
  default = "192.168.2.1"
}
variable "hamgmt_subnet_intrinsic_router_ip" {
  description = "Provide the IP address of the AWS intrinsic router (First IP from hamgmt_subnet)"
  default = "192.168.4.1"
}
variable "tag_name_prefix" {
  description = "Provide a tag prefix value that that will be used in the name tag for all resources"
  default = "stack-1"
}
variable "instance_type" {
  description = "Provide the instance type for the FortiGate instances"
  default = "c5.xlarge"
}
variable "license_type" {
  description = "Provide the license type for the FortiGate instances, byol or ond"
  default = "ond"
}
variable "ami" {
  description = "Provide an AMI for the FortiGate instances"
  default = ""
}
variable "keypair" {
  description = "Provide a keypair for accessing the FortiGate instance"
  default = "kp-poc-common"
}
variable "cidr_for_access" {
  description = "Provide a network CIDR for accessing the FortiGate instances"
  default = "0.0.0.0/0"
}