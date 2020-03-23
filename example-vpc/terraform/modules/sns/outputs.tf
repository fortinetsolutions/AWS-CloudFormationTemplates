output "arn" {
  value       = "${aws_sns_topic.sns_asg.arn}"
  description = "SNS Topic ARN"
}