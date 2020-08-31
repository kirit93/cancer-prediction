output "s3_lambda_arn" {
  value = "${aws_lambda_function.s3_lambda.arn}"
}

output "s3_lambda_invoke_arn" {
  value = "${aws_lambda_function.s3_lambda.invoke_arn}"
}

output "opencv_lambda_arn" {
  value = "${aws_lambda_function.opencv_lambda.arn}"
}

output "opencv_lambda_invoke_arn" {
  value = "${aws_lambda_function.opencv_lambda.invoke_arn}"
}