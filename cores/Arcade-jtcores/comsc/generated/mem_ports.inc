
    input cen1p5, cen3, // 3000000 = 24000000*1/8 Hz 
    input cen_fm2, cen_fm, // 3579544 = 24000000*9721/65177 Hz 

    // Audio channels
    
    output signed [15:0] fm,
    output signed [ 8:0] pcm,
    output [ 7:0] psga,
    output psga_rcen,
    output [ 7:0] psgb,
    output psgb_rcen,
    output [ 7:0] psgc,
    output psgc_rcen,
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
    input    [15:0] gfx1_data,
    output          gfx1_cs,
    output   [18:1] gfx1_addr,
    input           gfx1_ok,

    input    [15:0] gfx2_data,
    output          gfx2_cs,
    output   [18:1] gfx2_addr,
    input           gfx2_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [16:0] pcm_addr,
    input           pcm_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [17:0] main_addr,
    input           main_ok
