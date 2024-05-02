
    // Audio channels
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,
    output signed [11:0] pcm0,
    output signed [11:0] pcm1,
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
    output    vrom_cs,
    // Buses to BRAM

    // Buses to SDRAM
    input    [15:0] ram_data,
    output          ram_cs,
    output   [15:1] ram_addr,
    output          ram_we,
    output   [15:0] ram_din,
    output   [ 1:0] ram_dsn,
    input           ram_ok,

    input    [15:0] main_data,
    output          main_cs,
    output   [19:1] main_addr,
    input           main_ok,

    input    [ 7:0] snd1_data,
    output          snd1_cs,
    output   [14:0] snd1_addr,
    input           snd1_ok,

    input    [ 7:0] snd2_data,
    output          snd2_cs,
    output   [17:0] snd2_addr,
    input           snd2_ok,

    input    [31:0] map1_data,
    output   [16:2] map1_addr,
    input           map1_ok,

    input    [31:0] map2_data,
    output   [16:2] map2_addr,
    input           map2_ok,

    input    [15:0] char_data,
    output   [13:1] char_addr,
    input           char_ok,

    input    [15:0] scr1_data,
    output   [19:1] scr1_addr,
    input           scr1_ok,

    input    [15:0] scr2_data,
    output   [18:1] scr2_addr,
    input           scr2_ok,

    input    [15:0] obj_data,
    output   [21:1] obj_addr,
    input           obj_ok
