variable "access_key" {}
variable "secret_key" {}
variable "region" {
  description = "Provide the region to deploy the VPC in"
  default = "us-east-1"
}
variable "public_elb_type" {
  description = "Specify the public elb type if one is desired, nlb or alb"
  default = ""
}
variable "vpc_id" {
  description = "Provide ID for the VPC"
  default = "vpc-11111111111111111111"
}
variable "public_subnet1_id" {
  description = "Provide the ID for the first public subnet"
  default = "subnet-1111111111111111111"
}
variable "public_subnet2_id" {
  description = "Provide the ID for the second public subnet"
  default = "subnet-1111111111111111111"
}
variable "fgt1_id" {
  description = "Provide the ID for the first fgt instance"
  default = "instance-1111111111111111111"
}
variable "fgt2_id" {
  description = "Provide the ID for the second fgt instance"
  default = "instance-1111111111111111111"
}
variable "tag_name_prefix" {
  description = "Provide a common tag prefix value that will be used in the name tag for all resources"
  default = "stack-1"
}
variable "tag_name_unique" {
  description = "Provide a unique tag prefix value that will be used in the name tag for each modules resources"
  default = "automatically gathered by terraform modules"
}