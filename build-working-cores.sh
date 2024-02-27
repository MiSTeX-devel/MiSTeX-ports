#!/bin/bash
WORKING_CORES=$(awk '{ print $1 " " $5}' cores/Readme.md | grep works | awk '{ print $1 }' | sed 's/|//g')

BOARD="$1"

[ -z "$BOARD" ] && BOARD=mistex_boards/qmtech_xc7a100t_mistex.py

for core in $WORKING_CORES
do
    time python3 $BOARD cores/$core
done