resource "aws_s3_bucket" "melanoma_bucket" {
    bucket  = var.bucket
    acl     = "private"

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id   = aws_kms_key.s3_key.arn
                sse_algorithm       = "aws:kms"
            }
        }
    }

    versioning {
        enabled = true
    }  
}


resource "aws_kms_key" "s3_key" {
    description             = "This key is used to encrypt bucket objects"
    deletion_window_in_days = 10
}

resource "aws_s3_bucket_policy" "b" {
    bucket = aws_s3_bucket.melanoma_bucket.id

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "MYBUCKETPOLICY",
    "Statement": [
        {
            "Sid": "S3Permissions",
            "Action": "s3:*",
            "Effect": "Allow",
            "Principal": { 
                "AWS": "arn:aws:iam::287222052256:role/${var.lambda_role}" 
            },
            "Resource": [
                "arn:aws:s3:::${var.bucket}/*",
                "arn:aws:s3:::${var.bucket}"
            ]
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_object" "notebook" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/sagemaker/notebook/trainer.ipynb"
  source = "${path.module}/../../sources/notebook/trainer.ipynb"
}

resource "aws_s3_bucket_object" "script" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/sagemaker/scripts/training.py"
  source = "${path.module}/../../sources/scripts/training.py"
}

resource "aws_s3_bucket_object" "opencv_layer" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/lambda/functions/zipfiles/layers/opencv-python-layer-py36.zip"
  source = "${path.module}/../../sources/lambda/functions/zipfiles/layers/opencv-python-layer-py36.zip"
}

resource "aws_s3_bucket_object" "pydicom_layer" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/lambda/functions/zipfiles/layers/pydicom-layer-py37.zip"
  source = "${path.module}/../../sources/lambda/functions/zipfiles/layers/pydicom-layer-py37.zip"
}

resource "aws_s3_bucket_object" "numpy_layer" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/lambda/functions/zipfiles/layers/numpy-layer-py37.zip"
  source = "${path.module}/../../sources/lambda/functions/zipfiles/layers/numpy-layer-py37.zip"
}

resource "aws_s3_bucket_object" "opencv_lambda" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/lambda/functions/zipfiles/${var.lambda2_name}_function.zip"
  source = "${path.module}/../../sources/lambda/functions/zipfiles/${var.lambda2_name}_function.zip"
}

resource "aws_s3_bucket_object" "s3_lambda" {
  bucket = aws_s3_bucket.melanoma_bucket.id
  key = "sources/lambda/functions/zipfiles/${var.lambda1_name}_function.zip"
  source = "${path.module}/../../sources/lambda/functions/zipfiles/${var.lambda1_name}_function.zip"
}