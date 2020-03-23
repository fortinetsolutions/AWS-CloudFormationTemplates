output "vpc_id" {
  value       = "${module.vpc.vpc_id}"
  description = "The VPC Id of the newly created VPC."
}

output "public1_subnet_id" {
  value = "${module.public-subnet-1.id}"
}

output "private1_subnet_id" {
  value = "${module.private-subnet-1.id}"
}

output "fortigate_parameter_store_name" {
  value = "/${var.customer_prefix}/${var.environment}/${var.fgt_password_parameter_name}"
}

output "network_public_eni_id" {
  value = "${module.fortigate.network_public_interface_id}"
}

output "network_private_eni_id" {
  value = "${module.fortigate.network_private_interface_id}"
}
output "fortigate_instance_id" {
  value = "${module.fortigate.instance_id}"
}
