provider "aws" {
  access_key    = "${var.access_key}"
  secret_key    = "${var.secret_key}"
  region        = "${var.aws_region}"
}

resource "aws_sns_topic" "sns_asg" {
  name = "${var.customer_prefix}-${var.environment}-${var.asg_name}-fgt-asg"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = "${aws_sns_topic.sns_asg.arn}"
  protocol = "https"
  endpoint = "${var.notification_url}"
  endpoint_auto_confirms = true
}
