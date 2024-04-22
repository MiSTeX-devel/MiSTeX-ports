## notes to get toki working

**jtcores**

Needed an up to date version of mistex target. Latest development is in setup branch and this [PR](https://github.com/MiSTeX-devel/jtcores/pull/1) is needed.

**Modified sys files needed**

​    \- rtl/jtframe_emu.sv
​    \- ../jtcores/modules/jtframe/target/mistex/sys/pll/pll_0002_96.v

Cyclone IV PLL has one less output than Cyclone V PLLs.  In Cyclone V the last one is used for the phase shifted 96 MHz.   

As Toki runs at 96 MHz (JTFRAME_SDRAM96: 1) it needs that PS 96 MHz. 

For now I'm just replacing the phase shifted 48 MHz (clk48sh) with the phase shifted 96 MHz (using pll_0002_96.v) and using a modified jtframe_emu.sv  with    `assign SDRAM_CLK   = clk48sh;` instead of         `assign SDRAM_CLK   = clk96sh;`

**Defines needed**

```sh
#JTFRAME_MR_FASTIO: 0
```

~~MiSTeX framework still does not accept fast SD access used by 96 MHz cores so I just specify not to use MiSTeR FASTIO.~~

Update:  Compiled wore with that define commented out and worked.

JTFRAME_MR_FASTIO: 0   is only needed if define JTFRAME_CLK96 is set to 1. In toki that define was removed so by default JTFRAME_MR_FASTIO is 0.

```verilog
#from jtframe_mister.sv
`ifndef JTFRAME_MR_FASTIO
    `ifdef JTFRAME_CLK96
        `define JTFRAME_MR_FASTIO 1
    `else
      `define JTFRAME_MR_FASTIO 0
    `endif
`endif
```

