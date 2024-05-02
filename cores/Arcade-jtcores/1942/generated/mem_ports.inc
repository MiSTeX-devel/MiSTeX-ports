
    input cen1p5, cen3, cen6, cen12, // 12000000 = 48000000*1/4 Hz 

    // Audio channels
    
    output [ 9:0] psg0,
    output [ 9:0] psg1,
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
    output   [15:0] chram_din,
    input   [15:0] chram_o16,
    output   [10:1] tmap_addr,
    input   [15:0] tmap_dout,
    output   [10:1] chram_addr,
    // Buses to BRAM

    output   [ 1:0] chram_we, // Dual port for chram
    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [16:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [15:0] char_data,
    output   [12:1] char_addr,
    input           char_ok,

    input    [15:0] obj_data,
    output   [15:1] obj_addr,
    input           obj_ok,

    input    [31:0] scr_data,
    output   [15:2] scr_addr,
    input           scr_ok
