resource "aws_s3_bucket" "melanoma_bucket" {
    bucket  = "${var.namespace}-${var.bucket}"
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
                "AWS": [
                  "arn:aws:iam::287222052256:role/kt-melanoma-lambda-role",
                  "arn:aws:iam::287222052256:role/kt-melanoma-ec2-policy" 
                ]
            },
            "Resource": [
                "arn:aws:s3:::${var.namespace}-${var.bucket}/*",
                "arn:aws:s3:::${var.namespace}-${var.bucket}"
            ]
        }
    ]
}
POLICY
}