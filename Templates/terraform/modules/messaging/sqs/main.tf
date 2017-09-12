terraform {
  required_version = ">= 0.8, <= 0.9.11"
}

resource "aws_sqs_queue" "queue_name" {
  name                      = "${var.queue_name}"
  receive_wait_time_seconds = "${var.receive_wait_time_seconds}"
}
