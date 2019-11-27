output "nlb_id" {
  value       = "${aws_lb.public_nlb.id}"
  description = "Network Load Balancer Id"
}
output "nlb_dns" {
  value       = "${aws_lb.public_nlb.dns_name}"
  description = "Network Load Balancer dns name"
}
output "target_group_arns" {
  value       = "${aws_lb_target_group.nlb_target_group.arn}"
  description = "Network Load Balancer Target Group ARN"
}
output "target_group_name" {
  value       = "${aws_lb_target_group.nlb_target_group.name}"
  description = "Network Load Balancer Target Group Name"
}
