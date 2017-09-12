terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

resource "aws_sns_topic" "s3_dirty_notifications" {
  name = "${var.sns_topic}"
}
