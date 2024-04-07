#!/bin/bash
WORKING_CORES=$(awk '{ print $1 " " $7}' cores/Readme.md | grep works | awk '{ print $1 }' | sed 's/|//g')

BOARD="$1"

[ -z "$BOARD" ] && BOARD=mistex_boards/qmtech_xc7a100t_mistex.py
[ -z "$NUM_PROCS" ] && NUM_PROCS=1

echo $WORKING_CORES | xargs -d ' ' -I @ -P $NUM_PROCS python3 $BOARD cores/@
