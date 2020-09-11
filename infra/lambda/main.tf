data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "lambda_function" {
    function_name = "${var.namespace}-${var.lambda_name}"
    role = aws_iam_role.lambda_role.arn
    handler = "${var.lambda_name}.lambda_handler"
    runtime = var.runtime #"python3.6"
    s3_bucket = var.bucket
    s3_key = var.function_key #"sources/lambda/functions/zipfiles/${var.lambda_name}_function.zip"

    layers = var.layers #[aws_lambda_layer_version.pydicom_layer.arn, aws_lambda_layer_version.numpy_layer.arn]
    memory_size = "3008"
    timeout = "900"
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
    name = "${var.namespace}-lambda-policy"
    description = "Allow lambda to read and write from S3 bucket"
    policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
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
            "iam:ListRoles",
            "iam:GetRole",
            "iam:PassRole"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "logs:*"
        ]
        resources = [
            "arn:aws:logs:*:*:*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "s3:*"
        ]
        resources = [
            "arn:aws:s3:::${var.bucket}",
            "arn:aws:s3:::${var.bucket}/*"
        ]
    }
    statement {
        effect = "Allow"
        actions = [
            "kms:*"
        ]
        resources = [
            "*"
        ]
    }
}
