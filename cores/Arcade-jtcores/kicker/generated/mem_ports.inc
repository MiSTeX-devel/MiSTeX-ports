
    input ti2_cen, ti1_cen, cpu4_cen, // 6144230 = 24576920*1/4 Hz 

    // Audio channels
    
    output signed [10:0] ti1,
    output signed [10:0] ti2,
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
    input    [31:0] scr_data,
    output          scr_cs,
    output   [14:2] scr_addr,
    input           scr_ok,

    input    [31:0] objrom_data,
    output          objrom_cs,
    output   [15:2] objrom_addr,
    input           objrom_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [15:0] pcm_addr,
    input           pcm_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [15:0] main_addr,
    input           main_ok
