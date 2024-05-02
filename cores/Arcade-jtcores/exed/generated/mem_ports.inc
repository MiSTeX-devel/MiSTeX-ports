
    // Audio channels
    
    output [ 9:0] psg0,
    output signed [10:0] psg1,
    output signed [10:0] psg2,
    // Memory ports
    input   [21:0]  prog_addr,
    input   [ 7:0]  prog_data,
    input           prog_we,
    input   [ 1:0]  prog_ba,
    input   [25:0]  ioctl_addr,
`ifdef JTFRAME_PROM_START
    input           prom_we,
`endif
    output reg [21:0] post_addr,

    output reg [25:0] pre_addr,

`ifdef JTFRAME_HEADER
    input           header,
`endif
`ifdef JTFRAME_IOCTL_RD
    input           ioctl_ram,
    input           ioctl_wr,
    output   [ 7:0] ioctl_din,
    input    [ 7:0] ioctl_dout, `endif
    input           ioctl_cart,
    // Explicit ports
    // Buses to BRAM

    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [16:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] map1_data,
    output          map1_cs,
    output   [13:0] map1_addr,
    input           map1_ok,

    input    [15:0] map2_data,
    output          map2_cs,
    output   [12:1] map2_addr,
    input           map2_ok,

    input    [15:0] char_data,
    output   [13:1] char_addr,
    input           char_ok,

    input    [31:0] scr1_data,
    output   [14:2] scr1_addr,
    input           scr1_ok,

    input    [31:0] scr2_data,
    output   [13:2] scr2_addr,
    input           scr2_ok,

    input    [15:0] obj_data,
    output   [14:1] obj_addr,
    input           obj_ok
