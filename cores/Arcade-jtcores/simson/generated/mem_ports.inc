
    input cen12, cen24, // 24000000 = 48000000*1/2 Hz 
    input cen_fm2, cen_fm, // 3579544 = 48000000*4808/64473 Hz 

    // Audio channels
    output signed [15:0] snd_l,
    output signed [15:0] snd_r,
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
    output   [7:0] ram_din,
    input   [7:0] ram_dout,
    output    ram_we,
    output   [6:0] nv_addr,
    output   [7:0] nv_din,
    input   [7:0] nv_dout,
    output    nv_we,
    // Buses to BRAM

    
    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [18:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [16:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcma_data,
    output          pcma_cs,
    output   [20:0] pcma_addr,
    input           pcma_ok,

    input    [ 7:0] pcmb_data,
    output          pcmb_cs,
    output   [20:0] pcmb_addr,
    input           pcmb_ok,

    input    [ 7:0] pcmc_data,
    output          pcmc_cs,
    output   [20:0] pcmc_addr,
    input           pcmc_ok,

    input    [ 7:0] pcmd_data,
    output          pcmd_cs,
    output   [20:0] pcmd_addr,
    input           pcmd_ok,

    input    [31:0] lyrf_data,
    output          lyrf_cs,
    output   [19:2] lyrf_addr,
    input           lyrf_ok,

    input    [31:0] lyra_data,
    output          lyra_cs,
    output   [19:2] lyra_addr,
    input           lyra_ok,

    input    [31:0] lyrb_data,
    output          lyrb_cs,
    output   [19:2] lyrb_addr,
    input           lyrb_ok,

    input    [31:0] lyro_data,
    output          lyro_cs,
    output   [21:2] lyro_addr,
    input           lyro_ok
