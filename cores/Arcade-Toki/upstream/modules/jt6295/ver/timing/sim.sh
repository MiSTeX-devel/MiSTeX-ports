#!/bin/bash

iverilog test.v ../../hdl/jt6295_timing.v -o sim && sim -lxt
rm -f sim