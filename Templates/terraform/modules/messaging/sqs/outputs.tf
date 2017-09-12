output "sqs_name" {
    value = "${aws_sqs_queue.queue_name.id}"
}

output "sqs_arn" {
    value = "${aws_sqs_queue.queue_name.arn}"
}
