variable bucket {}
variable s3_key {}
variable layer_name {}
variable namespace {}

variable runtime {
    type    = list(string)
    default = ["python3.6"]
}

output "layer_arn" {
    value = aws_lambda_layer_version.lambda_layer.arn
}

output "layer_runtimes" {
    value = aws_lambda_layer_version.lambda_layer.compatible_runtimes
}

resource "aws_lambda_layer_version" "lambda_layer" {
    s3_bucket = var.bucket
    s3_key = var.s3_key #"sources/lambda/functions/zipfiles/layers/opencv-python-layer-py36.zip"
    layer_name = "${var.namespace}-${var.layer_name}"
    compatible_runtimes = var.runtime
}
