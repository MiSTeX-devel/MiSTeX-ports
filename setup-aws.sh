#!/bin/bash
# this sets up an AWS Vivado instance to compile MiSTeX ports
sudo apt update
sudo apt install -y python3-pip
sudo apt install -y python3-venv
git clone --recursive https://github.com/MiSTeX-devel/MiSTeX-ports.git ports
cd ports
python -m venv venv
source ./venv/bin/activate
pip install -r requirements.txt
