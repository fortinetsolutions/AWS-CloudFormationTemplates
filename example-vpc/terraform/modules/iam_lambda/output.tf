output "lambda_iam_role_name" {
  value = "${aws_iam_role.zappa_deployed_lambda_role.name}"
  description = "Llambda function name"
}