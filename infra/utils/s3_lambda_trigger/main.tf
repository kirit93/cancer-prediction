variable function_arn {}
variable filter_suffix {}
variable bucketarn {}
variable bucketid {}

resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = var.bucketid

    lambda_function {
        lambda_function_arn = var.function_arn #aws_lambda_function.s3_lambda.arn
        events              = ["s3:ObjectCreated:*"]
        filter_suffix       = var.filter_suffix
    }

    depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
    statement_id  = "AllowExecutionFromS3Bucket"
    action        = "lambda:InvokeFunction"
    function_name = var.function_arn # aws_lambda_function.s3_lambda.arn
    principal     = "s3.amazonaws.com"
    source_arn    = var.bucketarn
}