#!/usr/bin/env bash

# ---------------------------- INSTALL NOTES ----------------------------
# To properly setup the AWS CLI, make sure that this shell script is run with the two required positional args:
#   $1 :: (string) AWS Access Key ID
#   $2 :: (string) AWS Secret Key
#
# Also make sure to give the script permission to run!:
#    chmod 755 /home/ubuntu/install.sh
#
# -----------------------------------------------------------------------


# ++++++++++++++++++++ START ANACONDA INSTALL +++++++++++++++++++++
cd /home/ubuntu
su ubuntu

# Download the Linux Anaconda Distribution
wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O /tmp/anaconda3.sh

# Run the installer (installing without -p should automatically install into '/' (root dir)
bash /tmp/anaconda3.sh -b -p /home/ubuntu/anaconda3
rm /tmp/anaconda3.sh

### Run the conda init script to setup the shell
echo ". /home/ubuntu/anaconda3/etc/profile.d/conda.sh" >> /home/ubuntu/.bashrc
. /home/ubuntu/anaconda3/etc/profile.d/conda.sh
source /home/ubuntu/.bashrc

# Create a base Python3 environment separate from the base env
conda create -y --name ucsf_env python=3.6

# +++++++++++++++++++++ END ANACONDA INSTALL ++++++++++++++++++++++


# ++++++++++++++ SETUP ENV +++++++++++++++

# Install necessary Python packages
# Note that 'source' is deprecated, so now we should be using 'conda' to activate/deactivate envs
conda activate ucsf_env
conda install -y -c conda-forge awscli

# Setup the credentials for the AWS CLI
aws configure set aws_access_key_id $1
aws configure set aws_secret_access_key $2

# ++++++++++++ END  +++++++++++++