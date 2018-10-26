variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to deploy the VPC in"
  default = "us-east-1"
}
variable "availability_zone" {
  description = "Provide the availability zone to create the subnets in"
  default = "us-east-1a"
}
variable "vpc_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "192.168.0.0/16"
}
variable "public_subnet_cidr" {
  description = "Provide the network CIDR for the public subnet"
  default = "192.168.1.0/24"
}
variable "private_subnet_cidr" {
  description = "Provide the network CIDR for the private subnet"
  default = "192.168.2.0/24"
}
variable "hasync_subnet_cidr" {
  description = "Provide the network CIDR for the hasync subnet"
  default = "192.168.3.0/24"
}
variable "hamgmt_subnet_cidr" {
  description = "Provide the network CIDR for the hamgmt subnet"
  default = "192.168.4.0/24"
}
variable "tag_name_prefix" {
  description = "Provide a tag prefix value that that will be used in the name tag for all resources"
  default = "stack-1"
}