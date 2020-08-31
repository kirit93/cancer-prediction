resource "aws_s3_bucket" "bucket" {
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

resource "aws_s3_bucket_object" "notebook" {
  bucket = aws_s3_bucket.bucket.id
  key = "sagemaker/source/notebook/trainer.ipynb"
  source = "${path.module}/../../sources/notebook/trainer.ipynb"
}

resource "aws_s3_bucket_object" "script" {
  bucket = aws_s3_bucket.bucket.id
  key = "sagemaker/source/scripts/training.py"
  source = "${path.module}/../../sources/scripts/training.py"
}