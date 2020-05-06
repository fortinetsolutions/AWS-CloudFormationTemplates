output "instance_id" {
  value       = "${aws_instance.ec2.id}"
  description = "Instance Id"
}
output "key_name" {
  value       = "${aws_instance.ec2.key_name}"
  description = "Instance Id key name"
}
output "public_ip" {
  value       = "${aws_instance.ec2.public_ip}"
  description = "Instance Id public ip"
}
output "private_ip" {
  value       = "${aws_instance.ec2.private_ip}"
  description = "Instance Id private ip"
}
