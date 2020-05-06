output "id" {
  value       = "${aws_security_group.sg.id}"
  description = "Security Group Id"
}
output "arn" {
  value       = "${aws_security_group.sg.arn}"
  description = "Security Group ARN"
}