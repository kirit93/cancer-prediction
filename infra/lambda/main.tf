data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucketid

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".dcm"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.opencv_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".npy"
  }

  depends_on = [
    aws_lambda_permission.allow_bucket1,
    aws_lambda_permission.allow_bucket2,
  ]

}

resource "aws_lambda_permission" "allow_bucket1" {
    statement_id  = "AllowExecutionFromS3Bucket1"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_lambda.arn
    principal     = "s3.amazonaws.com"
    source_arn    = var.bucketarn
}

resource "aws_lambda_permission" "allow_bucket2" {
    statement_id  = "AllowExecutionFromS3Bucket2"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.opencv_lambda.arn
    principal     = "s3.amazonaws.com"
    source_arn    = var.bucketarn
}

resource "aws_lambda_function" "s3_lambda" {
    function_name = "${var.namespace}-${var.lambda1_name}"
    role = aws_iam_role.lambda_role.arn
    handler = "${var.lambda1_name}.lambda_handler"
    runtime = "python3.7"
    filename = "${path.module}/../../sources/lambda/functions/zipfiles/${var.lambda1_name}_function.zip"

    layers = [aws_lambda_layer_version.pydicom_layer.arn, aws_lambda_layer_version.numpy_layer.arn]
    // TODO Handle code stored in S3

    memory_size = "3008"
    timeout = "900"
}

resource "aws_lambda_function" "opencv_lambda" {
    function_name = "${var.namespace}-${var.lambda2_name}"
    role = aws_iam_role.lambda_role.arn
    handler = "${var.lambda2_name}.lambda_handler"
    runtime = "python3.6"
    filename = "${path.module}/../../sources/lambda/functions/zipfiles/${var.lambda2_name}_function.zip"

    layers = [aws_lambda_layer_version.opencv_layer.arn]
    // TODO Handle code stored in S3

    memory_size = "3008"
    timeout = "900"
}

resource "aws_lambda_layer_version" "opencv_layer" {
    filename = "${path.module}/../../sources/lambda/functions/zipfiles/layers/opencv-python-layer-py36.zip"
    layer_name = "${var.namespace}-opencv-python36-layer"

    compatible_runtimes = ["python3.6"]
}

resource "aws_lambda_layer_version" "pydicom_layer" {
    filename = "${path.module}/../../sources/lambda/functions/zipfiles/layers/pydicom-layer-py37.zip"
    layer_name = "${var.namespace}-pydicom-python37-layer"

    compatible_runtimes = ["python3.7"]
}

resource "aws_lambda_layer_version" "numpy_layer" {
    filename = "${path.module}/../../sources/lambda/functions/zipfiles/layers/numpy-layer-py37.zip"
    layer_name = "${var.namespace}-numpy-python37-layer"

    compatible_runtimes = ["python3.7"]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.namespace}-lambda-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "lambda.amazonaws.com" ]
    }
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.namespace}-lambda-polciy"
  description = "Allow lambda to create model"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
        "lambda:*"
    ]
    resources = [
        "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ]
    resources = [
        "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
        "s3:GetObject",
        "s3:PutObject"
    ]
    resources = [
        "arn:aws:s3:::${var.bucketname}",
        "arn:aws:s3:::${var.bucketname}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
