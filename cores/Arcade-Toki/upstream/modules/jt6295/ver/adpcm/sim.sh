#!/bin/bash

FILES="test.v ../../hdl/jt6295_adpcm.v ../../hdl/jt6295_sh_rst.v"

if which ncverilog; then
    ncverilog $FILES  +access+r +define+SIMULATION \
        +define+NCVERILOG +define+SINESIM
else
    iverilog $FILES \
    -DSIMULATION -DSINESIM -o sim \
    || exit 1
    sim -lxt
fi