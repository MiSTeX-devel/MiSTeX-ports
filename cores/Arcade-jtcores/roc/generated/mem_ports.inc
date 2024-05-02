
    input cen_nc, cpu4_cen, // 6144230 = 24576920*1/4 Hz 

    // Audio channels
    
    output [ 7:0] psg0a,
    output [3:0] psg0a_rcen,
    output [ 7:0] psg0b,
    output [3:0] psg0b_rcen,
    output [ 7:0] psg0c,
    output [3:0] psg0c_rcen,
    output [ 7:0] psg1a,
    output [3:0] psg1a_rcen,
    output [ 7:0] psg1b,
    output [3:0] psg1b_rcen,
    output [ 7:0] psg1c,
    output [3:0] psg1c_rcen,
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
    output   [14:2] scr_addr,
    input           scr_ok,

    input    [31:0] objrom_data,
    output          objrom_cs,
    output   [15:2] objrom_addr,
    input           objrom_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [13:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [15:0] main_addr,
    input           main_ok
