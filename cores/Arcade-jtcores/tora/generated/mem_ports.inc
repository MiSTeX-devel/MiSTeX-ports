
    // Audio channels
    
    output signed [15:0] fm0,
    output signed [15:0] fm1,
    output [ 9:0] psg0,
    output [ 9:0] psg1,
    output signed [11:0] pcm,
    // Memory ports
    input   [21:0]  prog_addr,
    input   [ 7:0]  prog_data,
    input           prog_we,
    input   [ 1:0]  prog_ba,
    input   [25:0]  ioctl_addr,
`ifdef JTFRAME_PROM_START
    input           prom_we,
`endif
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
    input    [15:0] main_data,
    output          main_cs,
    output   [17:1] main_addr,
    input           main_ok,

    input    [15:0] map_data,
    output          map_cs,
    output   [14:1] map_addr,
    input           map_ok,

    input    [15:0] scr_data,
    output   [19:1] scr_addr,
    input           scr_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] snd2_data,
    output          snd2_cs,
    output   [15:0] snd2_addr,
    input           snd2_ok,

    input    [15:0] char_data,
    output   [14:1] char_addr,
    input           char_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [18:2] obj_addr,
    input           obj_ok
