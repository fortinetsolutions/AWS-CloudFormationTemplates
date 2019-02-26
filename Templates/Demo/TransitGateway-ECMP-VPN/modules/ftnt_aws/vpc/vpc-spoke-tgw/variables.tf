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
variable "vpc_cidr" {
  description = "Provide the network CIDR for the VPC"
  default = "10.0.0.0/16"
}
variable "private_subnet_cidr1" {
  description = "Provide the network CIDR for the private subnet1"
  default = "10.0.0.0/24"
}
variable "private_subnet_cidr2" {
  description = "Provide the network CIDR for the private subnet2"
  default = "10.0.1.0/24"
}
variable "transit_gateway_id" {
  description = "Provide the id of the transit gateway"
  default = "tgw..."
}
variable "transit_gateway_default_association_id" {
  description = "Provide the id of the default transit gateway association id"
  default = "tgw-rt..."
}
variable "transit_gateway_default_route_table_id" {
  description = "Provide the id of the default transit gateway route table to attach to"
  default = "tgw-rt..."
}
variable "transit_gateway_private_route_table" {
  description = "Provide the id of the private transit gateway route table to attach to"
  default = "tgw-rt..."
}
variable "tag_name_prefix" {
  description = "Provide a tag prefix value that that will be used in the name tag for all resources"
  default = "stack-1"
}
variable "tag_name_unique" {
  description = "Provide a unique tag prefix value that will be used in the name tag for each modules resources"
  default = ""
}