#!/usr/bin/env bash

# ---------------------------- INSTALL NOTES ----------------------------
# To properly setup the AWS CLI, make sure that this shell script is run with the two required positional args:
#   $1 :: (string) AWS Access Key ID
#   $2 :: (string) AWS Secret Key
#
# -----------------------------------------------------------------------


# ++++++++++++++++++++ START ANACONDA INSTALL +++++++++++++++++++++
cd /home/ubuntu

# Mount EBS volume to /data
sudo mkfs -t ext4 /dev/xvdf
sudo mkdir /data
sudo mount /dev/xvdf /data
cd /data
df -h .

# Ensure volume is mounted whenever instance starts up
sudo cp /etc/fstab /etc/fstab.bak
echo "/dev/xvdf /data ext4 defaults,nofail 0 0" > /etc/fstab
sudo mount -a

# Download the Linux Anaconda Distribution
wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh -O /tmp/anaconda3.sh

# Run the installer (installing without -p should automatically install into '/' (root dir)
bash /tmp/anaconda3.sh -b -p /home/ubuntu/anaconda3
rm /tmp/anaconda3.sh

### Run the conda init script to setup the shell
echo ". /home/ubuntu/anaconda3/etc/profile.d/conda.sh" >> /home/ubuntu/.bashrc
. /home/ubuntu/anaconda3/etc/profile.d/conda.sh

source /home/ubuntu/.bashrc

sudo apt-get update


# Create a base Python3 environment separate from the base env
conda create -y --name ucsf_env python=3.6

# +++++++++++++++++++++ END ANACONDA INSTALL ++++++++++++++++++++++

# ++++++++++++++ SETUP ENV +++++++++++++++

# Install necessary Python packages
conda activate ucsf_env
pip install jupyter

# Setup Jupyter
jupyter notebook --generate-config
cd .jupyter
echo "conf = get_config()" >> jupyter_notebook_config.py_
echo "conf.NotebookApp.ip = '0.0.0.0'" >> jupyter_notebook_config.py_
echo "conf.NotebookApp.port = 8888" >> jupyter_notebook_config.py_

# conda install -y -c conda-forge awscli
# # Setup the credentials for the AWS CLI (find better way to pass secret key)
# aws configure set aws_access_key_id AKIAUFX6EWWQO4VCJQQZ
# aws configure set aws_secret_access_key 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

# ++++++++++++ END  +++++++++++++