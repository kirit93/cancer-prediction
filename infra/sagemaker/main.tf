resource "aws_iam_role" "sagemaker_role" {
    name                = "${var.namespace}-sagemaker-role"
    path                = "/"
    assume_role_policy  = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
    statement {
        actions     = [ "sts:AssumeRole" ]
        principals {
            type        = "Service"
            identifiers = [ "sagemaker.amazonaws.com" ]
        }
    }
}

resource "aws_iam_policy" "sagemaker_policy" {
    name            = "${var.namespace}-sagemaker-policy"
    description     = "Allow Sagemaker to create model"
    policy          = data.aws_iam_policy_document.sagemaker_policy_doc.json
}

data "aws_iam_policy_document" "sagemaker_policy_doc" {
    statement {
        effect = "Allow"
        actions = [
            "sagemaker:*"
        ]
        resources = [
            "*"
        ]
    }
    statement {
        effect      = "Allow"
        actions     = [
            "cloudwatch:PutMetricData",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:DescribeLogStreams",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
        ]
        resources   = [
            "*"
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
            "comprehend:*",
            "iam:ListRoles",
            "iam:GetRole",
            "iam:PassRole"
        ]
        resources = [
            "*"
        ]
    }
}

resource "aws_iam_role_policy_attachment" "sagemaker_role_policy" {
    role = aws_iam_role.sagemaker_role.name
    policy_arn = aws_iam_policy.sagemaker_policy.arn
}

resource "aws_sagemaker_notebook_instance" "sagemaker_notebook" {
    name = "${var.namespace}-notebook-instance"
    role_arn = aws_iam_role.sagemaker_role.arn
    instance_type = "ml.m5.12xlarge"
    # lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.default.name
}

data "template_file" "init" {
  template = "${file("${path.module}/../../sources/sagemaker/scripts/sagemaker_init.sh")}"

  vars = {
    bucket_name = var.bucket
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "default" {
  name = "${var.namespace}-notebook-instance"
  on_start = base64encode(data.template_file.init.rendered)
}