
    input cen12, cen24, // 24000000 = 48000000*1/2 Hz 
    input cen_fm2, cen_fm, // 3579544 = 48000000*4808/64473 Hz 

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
    input   [7:0] pmc_dout,
    output    pmc_we,
    output   [7:0] ram_din,
    output    ram_we,
    output   [10:0] pmc_addr,
    input   [7:0] pmc2main_data,
    input   [7:0] ram_dout,
    output   [7:0] pmc_din,
    output    cpu2pmc_we,
    // Buses to BRAM

    
    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [17:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcma_data,
    output          pcma_cs,
    output   [18:0] pcma_addr,
    input           pcma_ok,

    input    [ 7:0] pcmb_data,
    output          pcmb_cs,
    output   [18:0] pcmb_addr,
    input           pcmb_ok,

    input    [31:0] lyrf_data,
    output          lyrf_cs,
    output   [20:2] lyrf_addr,
    input           lyrf_ok,

    input    [31:0] lyra_data,
    output          lyra_cs,
    output   [20:2] lyra_addr,
    input           lyra_ok,

    input    [31:0] lyrb_data,
    output          lyrb_cs,
    output   [20:2] lyrb_addr,
    input           lyrb_ok,

    input    [31:0] lyro_data,
    output          lyro_cs,
    output   [20:2] lyro_addr,
    input           lyro_ok
