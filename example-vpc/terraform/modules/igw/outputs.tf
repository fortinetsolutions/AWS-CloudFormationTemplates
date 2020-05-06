
output "igw_id" {
  value = "${aws_internet_gateway.igw.id}"
  description = "The Internet Gateway Id for the newly created VPC"
}
