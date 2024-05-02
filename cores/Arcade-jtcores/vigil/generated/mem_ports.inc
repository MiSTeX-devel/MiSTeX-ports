
    // Audio channels
    
    output signed [ 7:0] pcm,output signed [15:0] fm_l,
    output signed [15:0] fm_r,
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
    // Buses to BRAM

    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [17:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [15:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [15:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] scr1_data,
    output          scr1_cs,
    output   [17:2] scr1_addr,
    input           scr1_ok,

    input    [31:0] scr2_data,
    output          scr2_cs,
    output   [18:2] scr2_addr,
    input           scr2_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [18:2] obj_addr,
    input           obj_ok
