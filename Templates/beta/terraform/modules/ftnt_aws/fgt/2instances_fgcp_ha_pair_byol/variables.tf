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
variable "ami" {
  description = "Provide an AMI for the FortiGate instances"
  default = ""
}
variable "instance_type" {
  description = "Provide the instance type for the FortiGate instances"
  default = "c5.xlarge"
}
variable "keypair" {
  description = "Provide a keypair for accessing the FortiGate instance"
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
  description = "Provide the BYOL license filename for fgt1 and place the file in the root module folder"
  default = ""
}
variable "fgt2_byol_license" {
  description = "Provide the BYOL license filename for fgt2 and place the file in the root module folder"
  default = ""
}
variable "public_subnet_intrinsic_router_ip" {
  description = "Provide the IP address of the AWS intrinsic router (First IP from public_subnet)"
  default = "192.168.1.1"
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
variable "fgt1_public_ip" {
  description = "Provide the IP address in CIDR form for the public interface of fgt1 (IP from public_subnet)"
  default = "192.168.1.11/24"
}
variable "fgt1_private_ip" {
  description = "Provide the IP address in CIDR form for the private interface of fgt1 (IP from private_subnet)"
  default = "192.168.2.11/24"
}
variable "fgt1_hasync_ip" {
  description = "Provide the IP address for in CIDR form the ha sync interface of fgt1 (IP from hasync_subnet)"
  default = "192.168.3.11/24"
}
variable "fgt1_hamgmt_ip" {
  description = "Provide the IP address in CIDR form for the ha mgmt interface of fgt1 (IP from hamgmt_subnet)"
  default = "192.168.4.11/24"
}
variable "fgt2_public_ip" {
  description = "Provide the IP address in CIDR form for the public interface of fgt2 (IP from public_subnet)"
  default = "192.168.1.12/24"
}
variable "fgt2_private_ip" {
  description = "Provide the IP address in CIDR form for the private interface of fgt2 (IP from private_subnet)"
  default = "192.168.2.12/24"
}
variable "fgt2_hasync_ip" {
  description = "Provide the IP address in CIDR form for the ha sync interface of fgt2 (IP from hasync_subnet)"
  default = "192.168.3.12/24"
}
variable "fgt2_hamgmt_ip" {
  description = "Provide the IP address in CIDR form for the ha mgmt interface of fgt2 (IP from hamgmt_subnet)"
  default = "192.168.4.12/24"
}
variable "cluster_public_ip" {
  description = "Provide the IP address in CIDR form for the public interface of the cluster (IP from public_subnet)"
  default = "192.168.1.13/24"
}
variable "cluster_private_ip" {
  description = "Provide the IP address in CIDR form for the private interface of the cluster (IP from private_subnet)"
  default = "192.168.2.13/24"
}