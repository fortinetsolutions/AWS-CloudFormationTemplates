
output "elb_id" {
  value = "${aws_elb.external_elb.id}"
}

output "elb_name" {
  value = "${aws_elb.external_elb.name}"
}

output "elb_dns_name" {
  value = "${aws_elb.external_elb.dns_name}"
}
