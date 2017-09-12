output "sqs_name" {
    value = "${module.sqs.sqs_name}"
}

output "sqs_target_arn" {
    value = "${module.sqs.sqs_arn}"
}
