
    input cpu_cen, // 1536057 = 24576920*1/16 Hz 
    input ti2_cen, ti1_cen, // 3072115 = 24576920*1/8 Hz 
    input psg_cen, snd_cen, // 3579545 = 24576920*455/3124 Hz 

    // Audio channels
    
    output signed [ 9:0] vlm,
    output [1:0] vlm_rcen,
    output signed [10:0] psg,
    output [1:0] psg_rcen,
    output [ 7:0] rdac,
    output rdac_rcen,
    // Memory ports
    input   [21:0]  prog_addr,
    input   [ 7:0]  prog_data,
    input           prog_we,
    input   [ 1:0]  prog_ba,
    input   [25:0]  ioctl_addr,
`ifdef JTFRAME_PROM_START
    input           prom_we,
`endif
    output reg [ 7:0] post_data,

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
    output   [7:0] cpu_dout,
    input   [7:0] ram_dout,
    output    ram_we,
    // Buses to BRAM

    
    // Buses to SDRAM
    input    [31:0] scr_data,
    output   [14:2] scr_addr,
    input           scr_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [15:2] obj_addr,
    input           obj_ok,

    input    [ 7:0] pcm_data,
    output   [15:0] pcm_addr,
    input           pcm_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [13:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [15:0] main_addr,
    input           main_ok
