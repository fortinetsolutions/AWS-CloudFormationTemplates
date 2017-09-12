
output "wn_instance_id" {
  value = "${module.worker_node.instance_id}"
}

output "wn_public_ip" {
  value = "${module.worker_node.worker_node_eip}"
}

