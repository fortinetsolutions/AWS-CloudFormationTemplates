output "public1_subnet_id" {
  value = "${aws_subnet.az1-subnet-public.id}"
}

output "private1_subnet_id" {
  value = "${aws_subnet.az1-subnet-private.id}"
}

output "public2_subnet_id" {
  value = "${aws_subnet.az2-subnet-public.id}"
}

output "private2_subnet_id" {
  value = "${aws_subnet.az2-subnet-private.id}"
}

output "fortigate_security_group_id" {
  value = "${aws_security_group.allow_all.id}"
}

output "worker_node_security_group" {
  value = "${aws_security_group.ASSecurityGroup.id}"
}