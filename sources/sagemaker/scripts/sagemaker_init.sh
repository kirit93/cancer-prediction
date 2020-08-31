#!/bin/bash
set -e

cd /home/ec2-user/SageMaker
nohup aws s3 cp s3://${bucket_name}/sagemaker/source/notebook/trainer.ipynb .
nohup aws s3 cp s3://${bucket_name}/sagemaker/source/scripts/training.py .
