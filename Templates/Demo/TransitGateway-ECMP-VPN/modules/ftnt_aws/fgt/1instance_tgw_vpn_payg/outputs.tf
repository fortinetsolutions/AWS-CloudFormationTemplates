output "fgt_id" {
  value = "${aws_instance.fgt.id}"
}

output "fgt_public_ip" {
  value = "${aws_eip.eip.public_ip}"
}