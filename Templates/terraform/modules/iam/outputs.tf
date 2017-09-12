output "iam_worker_policy_name" {
    value = "${aws_iam_policy.WorkerPolicy.name}"
}

output "worker_policy_id" {
    value = "${aws_iam_policy.WorkerPolicy.id}"
}

output "worker_policy_arn" {
    value = "${aws_iam_policy.WorkerPolicy.arn}"
}

output "worker_policy_description" {
    value = "${aws_iam_policy.WorkerPolicy.description}"
}