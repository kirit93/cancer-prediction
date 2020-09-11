output "lambda_arn" {
  value = "${aws_lambda_function.lambda_function.arn}"
}

output "lambda_invoke_arn" {
  value = "${aws_lambda_function.lambda_function.invoke_arn}"
}
