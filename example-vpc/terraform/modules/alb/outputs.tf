output "target_group_arns" {
  value       = "${aws_lb_target_group.alb_target_group.arn}"
  description = "Network Load Balancer Id"
}
output "alb_dns" {
  value       = "${aws_lb.public_alb.dns_name}"
  description = "Network Load Balancer dns name"
}

