
output "instance_id" {
  value = "${aws_instance.fortigate.id}"
}

output "network_public_interface_id" {
  value = "${aws_network_interface.public_eni.id}"
}

output "network_private_interface_id" {
  value = "${aws_network_interface.private_eni.id}"
}