# JT6295
4 channel ADPCM decoder compatible with OKI 6295, by Jose Tejada (aka jotego)

You can show your appreciation through
* [Patreon](https://patreon.com/jotego), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

JT6295 is an ADPCM sound source written in Verilog, fully compatible with OKI MSM6295.

## Using JT6295 in a git project

If you are using JT6295 in a git project, the best way to add it to your project is:

1. Optionally fork JT6295's repository to your own GitHub account
2. Add it as a submodule to your git project: `git submodule add https://github.com/jotego/jt6295.git`
3. Now you can refer to the RTL files in **jt6295/hdl**

The advantages of a using a git submodule are:

1. Your project contains a reference to a commit of the JT6295 repository
2. As long as you do not manually update the JT6295 submodule, it will keep pointing to the same commit
3. Each time you make a commit in your project, it will include a pointer to the JT6295 commit used. So you will always know the JT6295 that worked for you
4. If JT6295 is updated and you want to get the changes, simply update the submodule using git. The new JT6295 commit used will be annotated in your project's next commit. So the history of your project will reflect that change too.
5. JT6295 files will be intact and you will use the files without altering them.

## Architecture

This design uses a pipeline in order to save FPGA resources and power. In that
sense, it would be very similar to the original design.

The behaviour of the original chip if a phrase command is send twice before the
end of it, has not been verified. The current JT6295 is to ignore commands to
the same channel as long as the playback has not ended.

## Port Description

Name     | Direction | Width | Purpose
---------|-----------|-------|--------------------------------------
rst      | input     |       | active-high asynchronous reset signal
clk      | input     |       | clock
cen      | input     |       | clock enable (positive edge).
ss       | input     | 1     | selects the data rate
din      | input     | 8     | input data from CPU
dout     | output    | 8     | output data to CPU
rom_addr | output    | 18    | Memory address to be read
rom_data | input     | 8     | Data read
rom_ok   | input     | 1     | high when rom_data is valid and matches rom_addr
sound    | output    | 14    | signed sound output

## Usage

This is a pin-to-pin compatible module with OKI MSM6295. If you are just going to use it on a retro core you don't need to know the internals of it just hook it up and be sure that the effective clock rate, i.e. clk&cen signal, is the intended frequency.

rom_ok signal should go down in one clock cycle (regardless of cen) if rom_data
is not valid after a change to rom_addr.

CPU and ROM interfaces do not follow the clock enable and operate at full speed.

The output data rate is 4x the expected from the ss pin as there is a 4x
interpolator built in, which eases most of the high frequency aliasing of the
signal. The interpolator can be disabled by setting the parameter INTERPOL to
zero.

There are two different interpolator filters, one filters the 4x upsampled data
at 0.25pi, as expected. The other one leaves some aliasing go through, by filtering
at 0.50pi. Use the second one when there is an additional external anti aliasing
filter, mimicking the original AA filter.

INTERPOL  |  Sampling Rate  |  AA filter
----------|-----------------|------------
 0        |      1          |  No
 1        |      4x         |  Yes, 0.25pi
 2        |      4x         |  Yes, 0.50pi

### ROM interface

Port     | Direction | Meaning
---------|-----------|----------------------------
rom_cs   | output    | high when address is valid
rom_addr | output    | Addres to be read
rom_data | input     | Data read from address
rom_ok   | input     | Data read is valid

Note that rom_ok is not valid for the clock cycle immediately after rising rom_cs. Or if rom_addr is changed while rom_cs is high. rom_addr must be stable once rom_cs goes high until rom_ok is asserted.

## FPGA arcade cores using this module:

* [Double Dragon 2](https://github.com/jotego/jtdd), by the same author
* [CAPCOM SYSTEM](https://github.com/jotego/jtcps1), by the same author

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)