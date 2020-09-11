provider "aws" {
    region  = "us-east-2"
    profile = "default"
    version = "2.23.0"
}

terraform {
    required_version = "0.13.1"
    backend "s3" {
        bucket = "kt-tfstate"
        key    = "terraform/terraform.tfstate"
        region = "us-east-2"
    }
}

# Create S3 bucket
module "s3" {
    source = "../s3"

    bucket = var.ucsf_bucket
    namespace = var.namespace
}

# Upload Lambda files to S3. Files include function zips and layer packages
module "lambda1_upload" {
    source = "../utils/s3_data_upload"
    bucketid = module.s3.s3_bucket_id
    key = var.lambda1
    path = var.lambda1_path
    depends_on = [module.s3]
}

module "lambda2_upload" {
    source = "../utils/s3_data_upload"
    bucketid = module.s3.s3_bucket_id
    key = var.lambda2
    path = var.lambda2_path
    depends_on = [module.s3]
}

module "numpy_layer_upload" {
    source = "../utils/s3_data_upload"
    bucketid = module.s3.s3_bucket_id
    key = "sources/lambda/functions/zipfiles/layers/numpy-layer-py37.zip"
    path = "../../sources/lambda/functions/zipfiles/layers/numpy-layer-py37.zip"
    depends_on = [module.s3]
}

# Create Lambda layers
module "numpy_layer" {
    source = "../utils/lambda_layer"
    bucket = module.numpy_layer_upload.bucket
    s3_key = module.numpy_layer_upload.key_name
    layer_name = "numpy_layer"
    namespace = var.namespace
    runtime = ["python3.6"]
    depends_on = [module.numpy_layer_upload]
}

# Create Lambda function taking code from the S3 bucket created above
module "lambda1" {
    source = "../lambda"

    bucket = module.lambda1_upload.bucket
    function_key = module.lambda1_upload.key_name
    namespace = var.namespace
    lambda_name = var.lambda1
    depends_on = [module.lambda1_upload]
    runtime = "python3.6"
    layers = [module.numpy_layer.layer_arn]
}

module "lambda2" {
    source = "../lambda"

    bucket = module.lambda2_upload.bucket
    function_key = module.lambda2_upload.key_name
    namespace = var.namespace
    lambda_name = var.lambda2
    depends_on = [module.lambda2_upload]
    runtime = "python3.6"
    layers = [module.numpy_layer.layer_arn]
}

# Create trigger between S3 bucket and Lambda function
module "lambda1_trigger" {
    source = "../utils/s3_lambda_trigger"
    function_arn = module.lambda1.lambda_arn
    filter_suffix = ".dcm"
    bucketarn = module.s3.s3_bucket_arn
    bucketid = module.s3.s3_bucket_id
}

module "lambda2_trigger" {
    source = "../utils/s3_lambda_trigger"
    function_arn = module.lambda2.lambda_arn
    filter_suffix = ".npy"
    bucketarn = module.s3.s3_bucket_arn
    bucketid = module.s3.s3_bucket_id
}

# module "ec2" {
#     source = "../ec2"

#     namespace = var.namespace
#     instance_type = var.instance_type
#     subnet_id = var.subnet_id
#     vpc = var.vpc_id
# }

# module "sqs" {
#     source = "../sqs"

#     namespace = var.namespace
#     bucketid = module.s3.s3_bucket_id
#     bucketarn = module.s3.s3_bucket_arn
# }