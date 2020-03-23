output "lambda_arn" {
  value       = "${aws_lambda_function.lambda.arn}"
  description = "Lambda Function ARN"
}
output "lambda_invoke_arn" {
  value       = "${aws_lambda_function.lambda.invoke_arn}"
  description = "Lambda API Gateway Invoke ARN"
}
output "lambda_function_name" {
  value = "${aws_lambda_function.lambda.function_name}"
  description = "Llambda function name"
}
