output "vpc_id" {
  value       = "${aws_vpc.vpc.id}"
  description = "The VPC Id of the newly created VPC."
}

output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
  description = "The Internet Gateway Id for the newly created VPC"
}

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
