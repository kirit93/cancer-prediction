provider "aws" {
    region  = "us-east-2"
    profile = "default"
    version = "2.23.0"
}

terraform {
    required_version = "0.12.24"
    backend "s3" {
        bucket = "kt-tfstate"
        key    = "terraform/terraform.tfstate"
        region = "us-east-2"
    }
}

module "s3" {
    source = "../s3"

    bucket = var.ucsf_bucket
    lambda1_name = var.lambda1
    lambda2_name = var.lambda2
}

module "lambda" {
    source = "../lambda"

    bucket = var.ucsf_bucket
    bucketid = module.s3.s3_bucket_id
    bucketarn = module.s3.s3_bucket_arn
    lambda1_name = var.lambda1
    lambda2_name = var.lambda2
    namespace = var.namespace
}

module "sagemaker" {
    source = "../sagemaker"

    namespace = var.namespace
    bucket = var.ucsf_bucket
}