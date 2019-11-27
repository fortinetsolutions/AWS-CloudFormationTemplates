variable "access_key" {}
variable "secret_key" {}

variable "aws_region" {
    description = "Region for the DG VPC"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
}

variable "public_subnet_cidr_1" {
    description = "CIDR for the Public Subnet"
}

variable "private_subnet_cidr_1" {
    description = "CIDR for the Private Subnet"
}

variable "public_subnet_cidr_2" {
    description = "CIDR for the Public Subnet"
}

variable "private_subnet_cidr_2" {
    description = "CIDR for the Private Subnet"
}


variable "availability_zone1" {
  description = "Availabilty Zone One"
}


variable "availability_zone2" {
  description = "Availabilty Zone Two"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
}

