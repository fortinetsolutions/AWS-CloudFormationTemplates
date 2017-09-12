variable "aws_key_path" {
    description     = "Key for ec2 instances"
    default         = "~/certificates/mdwadmin-iam-virginia.pem"
}

variable "aws_region" {
    description = "Region for the DG VPC"
    default = "us-west-2"
}

variable "customer_prefix" {
  description = "Customer Prefix to apply to all resources"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
    description = "CIDR for the Public Subnet"
    default = "10.0.0.0/24"
}

variable "private_subnet_cidr_1" {
    description = "CIDR for the Private Subnet"
    default = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
    description = "CIDR for the Public Subnet"
    default = "10.0.2.0/24"
}

variable "private_subnet_cidr_2" {
    description = "CIDR for the Private Subnet"
    default = "10.0.3.0/24"
}


variable "avalability_zone_1" {
  description = "Availabilty Zone One"
}


variable "avalability_zone_2" {
  description = "Availabilty Zone Two"
}

variable "environment" {
  description = "The Tag Environment in the S3 tag"
  default = "stage"
}

variable instance_id_a {
  description = "Instance ID for OnDemandA"
}

variable instance_id_b {
  description = "Instance ID for OnDemandB"
}

variable private_interface_id_a {
  description = "Private Interface ID for OnDemandA"
}

variable private_interface_id_b {
  description = "Private Interface ID for OnDemandB"
}

variable "amis" {
    description = "AMIs by region"
    default = {
        us-west-2-fgtami        = "ami-933797f3"
        us-west-2-workerami     = "ami-752ab815"
    }
}
