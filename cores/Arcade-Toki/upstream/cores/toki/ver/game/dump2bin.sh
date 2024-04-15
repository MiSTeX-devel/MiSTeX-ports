#!/bin/bash

DUMP=dump.bin

if [ ! -z "$1"    ]; then DUMP="$1"; fi
if [ ! -e "$DUMP" ]; then "Cannot find $DUMP"; exit 1; fi


dd if="$DUMP" of=rest.bin bs=256 skip=0
