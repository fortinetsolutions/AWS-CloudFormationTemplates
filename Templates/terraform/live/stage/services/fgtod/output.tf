
output "instance_id_a" {
  value = "${module.fgt_a.instance_id}"
}

output "private_ip_a" {
  value = "${module.fgt_a.private_ip}"
}


output "network_private_interface_id_a" {
  value = "${module.fgt_a.network_private_interface_id}"
}

output "instance_id_b" {
  value = "${module.fgt_b.instance_id}"
}

output "private_ip_b" {
  value = "${module.fgt_b.private_ip}"
}

output "network_private_interface_id_b" {
  value = "${module.fgt_b.network_private_interface_id}"
}
