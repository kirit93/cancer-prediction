#!/bin/bash
set -e

cd /home/ec2-user/SageMaker
nohup aws s3 cp s3://${bucket_name}/sagemaker/notebook/trainer.ipynb .
nohup aws s3 cp s3://${bucket_name}/sagemaker/scripts/training.py .
