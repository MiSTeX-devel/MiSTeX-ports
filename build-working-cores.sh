#!/bin/bash
WORKING_CORES=$(awk '{ print $1 " " $5}' cores/Readme.md | grep works | awk '{ print $1 }' | sed 's/|//g')

for core in $WORKING_CORES
do
    time python $1 cores/$core
done