
    input mcu_cen, cen3, // 3000000 = 24000000*1/8 Hz 

    input nc_cen4, video_cen8, // 8000000 = 48000000*1/6 Hz 
    input cen_fm2, cen_fm, // 3579544 = 48000000*4808/64473 Hz 

    // Audio channels
    output signed [15:0] fm_l,
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
    input    [15:0] main_data,
    output          main_cs,
    output   [17:1] main_addr,
    input           main_ok,

    input    [15:0] scr2_data,
    output   [15:1] scr2_addr,
    input           scr2_ok,

    input    [15:0] char_data,
    output   [13:1] char_addr,
    input           char_ok,

    input    [15:0] scr1_data,
    output   [17:1] scr1_addr,
    input           scr1_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [17:2] obj_addr,
    input           obj_ok
