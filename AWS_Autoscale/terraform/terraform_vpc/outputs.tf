output "vpc_id" {
  value       = "${module.vpc.vpc_id}"
  description = "The VPC Id of the newly created VPC."
}

output "igw_id" {
  value = "${module.vpc.igw_id}"
  description = "The Internet Gateway Id for the newly created VPC"
}

output "public1_subnet_id" {
  value = "${module.vpc.public1_subnet_id}"
}

output "private1_subnet_id" {
  value = "${module.vpc.private1_subnet_id}"
}

output "public2_subnet_id" {
  value = "${module.vpc.public2_subnet_id}"
}

output "private2_subnet_id" {
  value = "${module.vpc.private2_subnet_id}"
}
