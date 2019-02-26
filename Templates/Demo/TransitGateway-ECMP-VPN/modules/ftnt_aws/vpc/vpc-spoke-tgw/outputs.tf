output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "private_subnet1_id" {
  value = "${aws_subnet.private_subnet1.id}"
}

output "private_subnet2_id" {
  value = "${aws_subnet.private_subnet2.id}"
}