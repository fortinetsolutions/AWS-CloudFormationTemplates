output "sns_name" {
    value = "${aws_sns_topic.s3_dirty_notifications.name}"
}