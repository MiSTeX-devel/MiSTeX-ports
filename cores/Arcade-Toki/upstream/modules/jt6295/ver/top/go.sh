#!/bin/bash

if which ncverilog; then
    ncverilog -f test.f  +access+r +define+SIMULATION +define+NCVERILOG
else
    iverilog -f test.f -DSIMULATION -o sim || exit 1
    sim -lxt
fi