#!/bin/bash
# this sets up an AWS Vivado instance to compile MiSTeX ports
sudo apt update
sudo apt install -y python3-pip python3-venv meson gcc-riscv64-unknown-elf
git clone --recursive https://github.com/MiSTeX-devel/MiSTeX-ports.git ports
cd ports
cd cores/Arcade-jtcores/jtcores/
git -c submodule."modules/jt900h".update=none -c submodule."modules/jtframe/target/pocket".update=none submodule update --init --recursive
cd -
pip install virtualenv
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
