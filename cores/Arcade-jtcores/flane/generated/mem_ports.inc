
    input cen1p5, cen3, cen6, cen12, // 12000000 = 24000000*1/2 Hz 

    // Audio channels
    
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
    input    [15:0] gfx_data,
    output          gfx_cs,
    output   [18:1] gfx_addr,
    input           gfx_ok,

    input    [ 7:0] pcma_data,
    output          pcma_cs,
    output   [16:0] pcma_addr,
    input           pcma_ok,

    input    [ 7:0] pcmb_data,
    output          pcmb_cs,
    output   [16:0] pcmb_addr,
    input           pcmb_ok,

    input    [ 7:0] pcmc_data,
    output          pcmc_cs,
    output   [18:0] pcmc_addr,
    input           pcmc_ok,

    input    [ 7:0] pcmd_data,
    output          pcmd_cs,
    output   [18:0] pcmd_addr,
    input           pcmd_ok,

    input    [ 7:0] main_data,
    output          main_cs,
    output   [16:0] main_addr,
    input           main_ok
