output "vpc_id" {
  value       = "${aws_vpc.vpc.id}"
  description = "The VPC Id of the newly created VPC."
}
