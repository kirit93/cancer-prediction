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
  source = "./s3"

  bucket = "kt-melanoma-kt-data"
}

module "sagemaker" {
  source = "./sagemaker"

  namespace = "kt-melanoma"
  bucket_name = "kt-melanoma-kt-data"
}

module "lambda" {
    source = "./lambda"

	bucketname = "kt-melanoma-kt-data"
    bucketid = module.s3.s3_bucket
    bucketarn = module.s3.s3_bucket_arn
    lambda1_name = "dcm_conversion"
    lambda2_name = "opencv_preprocessing"
    namespace = "kt-melanoma"
}

