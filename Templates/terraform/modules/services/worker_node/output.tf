
output "instance_id" {
  value = "${aws_instance.worker_node.id}"
}

output "private_ip" {
  value = "${aws_network_interface.ENI0.private_ip}"
}

output  "worker_node_eip" {
  value = "${aws_eip.EIP.public_ip}"
}