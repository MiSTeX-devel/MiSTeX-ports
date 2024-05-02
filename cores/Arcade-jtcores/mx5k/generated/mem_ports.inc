
    input cen1p5, cen3, // 12000000 = 24000000*1/2 Hz 
    input cen_fm2, cen_fm, // 3579544 = 24000000*9721/65177 Hz 

    // Audio channels
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,
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
    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [15:0] gfx1_data,
    output          gfx1_cs,
    output   [18:1] gfx1_addr,
    input           gfx1_ok,

    input    [ 7:0] pcma_data,
    output          pcma_cs,
    output   [17:0] pcma_addr,
    input           pcma_ok,

    input    [ 7:0] pcmb_data,
    output          pcmb_cs,
    output   [17:0] pcmb_addr,
    input           pcmb_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [17:0] main_addr,
    input           main_ok
