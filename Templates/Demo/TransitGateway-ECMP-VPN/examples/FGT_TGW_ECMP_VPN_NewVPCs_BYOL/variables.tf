variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to deploy the VPC in"
  default = "us-east-1"
}
variable "availability_zone1" {
  description = "Provide the first availability zone to create the subnets in"
  default = "us-east-1a"
}
variable "availability_zone2" {
  description = "Provide the second availability zone to create the subnets in"
  default = "us-east-1b"
}
variable "security_vpc_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "10.0.0.0/16"
}
variable "security_vpc_public_subnet_cidr1" {
  description = "Provide the network CIDR for the public subnet1 in security vpc"
  default = "10.0.0.0/24"
}
variable "security_vpc_public_subnet_cidr2" {
  description = "Provide the network CIDR for the public subnet2 in security vpc"
  default = "10.0.1.0/24"
}
variable "spoke_vpc1_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "10.1.0.0/16"
}
variable "spoke_vpc1_private_subnet_cidr1" {
  description = "Provide the network CIDR for the private subnet1 in spoke vpc1"
  default = "10.1.0.0/24"
}
variable "spoke_vpc1_private_subnet_cidr2" {
  description = "Provide the network CIDR for the private subnet2 in spoke vpc1"
  default = "10.1.1.0/24"
}
variable "spoke_vpc2_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "10.2.0.0/16"
}
variable "spoke_vpc2_private_subnet_cidr1" {
  description = "Provide the network CIDR for the private subnet1 in spoke vpc2"
  default = "10.2.0.0/24"
}
variable "spoke_vpc2_private_subnet_cidr2" {
  description = "Provide the network CIDR for the private subnet2 in spoke vpc2"
  default = "10.2.1.0/24"
}
variable "ami" {
  description = "Provide an AMI for the FortiGate instances"
  default = "automatically gathered by terraform modules"
}
variable "instance_type" {
  description = "Provide the instance type for the FortiGate instances"
  default = "c5.large"
}
variable "keypair" {
  description = "Provide a keypair for accessing the FortiGate instances"
  default = "kp-poc-common"
}
variable "cidr_for_access" {
  description = "Provide a network CIDR for accessing the FortiGate instances"
  default = "0.0.0.0/0"
}
variable "license_type" {
  description = "Provide the license type for the FortiGate instances, byol or ond"
  default = "byol"
}
variable "fgt1_byol_license" {
  description = "Provide the BYOL license filename for the first FortiGate instance, and place the file in the root module folder"
  default = ""
}
variable "fgt2_byol_license" {
  description = "Provide the BYOL license filename for the second FortiGate instance, and place the file in the root module folder"
  default = ""
}
variable "fgt_bgp_asn" {
  description = "Provide the BGP ASN for the FortiGate instances"
  default = "65000"
}
variable "public_elb_type" {
  description = "Specify the public elb type if one is desired, nlb or alb"
  default = ""
}
variable "fgt1_loopback_ip" {
  description = "Provide an IP address for the loopback interface of the first FortiGate instance"
  default = "100.64.0.1"
}
variable "fgt2_loopback_ip" {
  description = "Provide an IP address for the loopback interface of the second FortiGate instance"
  default = "100.64.0.2"
}
variable "tag_name_prefix" {
  description = "Provide a common tag prefix value that will be used in the name tag for all resources"
  default = "stack-1"
}
variable "tag_name_unique" {
  description = "Provide a unique tag prefix value that will be used in the name tag for each modules resources"
  default = "automatically gathered by terraform modules"
}