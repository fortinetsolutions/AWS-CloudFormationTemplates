
output "instance_id" {
  value = "${aws_instance.fortigate.id}"
}

output "private_ip" {
  value = "${aws_network_interface.ENI0.private_ip}"
}

output "network_private_interface_id" {
  value = "${aws_network_interface.ENI1.id}"
}
