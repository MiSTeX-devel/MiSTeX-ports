#!/bin/bash

start=$1
end=$2
skip=$((0x$start))
echo $skip

dd if=rom.bin of=cut.bin ibs=1 skip=$skip count=$(( 0x$end-0x$start ))c