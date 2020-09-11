variable bucketid {}
variable key {}
variable path {}

output "key_name" {
  value = aws_s3_bucket_object.object.key
}

output "bucket" {
  value = aws_s3_bucket_object.object.bucket
}

resource "aws_s3_bucket_object" "object" {
  bucket = var.bucketid
  key = var.key # "sources/sagemaker/notebook/trainer.ipynb"
  source = var.path # "${path.module}/../../../sources/notebook/trainer.ipynb"
}
