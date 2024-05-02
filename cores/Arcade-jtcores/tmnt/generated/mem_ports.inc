
    input cen_fm2, cen_fm, // 3579544 = 48000000*4808/64473 Hz 
    input cen_20, cen_40, cen_80, cen_160, cen_320, cen_640, // 640000 = 48000000*1/75 Hz 

    // Audio channels
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,output signed [15:0] k60_l,
    output signed [15:0] k60_r,
    output signed [11:0] pcm,
    output signed [15:0] title,
    output signed [ 8:0] upd,
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
    input    [15:0] ram_data,
    output          ram_cs,
    output   [14:1] ram_addr,
    output          ram_we,
    output   [15:0] ram_din,
    output   [ 1:0] ram_dsn,
    input           ram_ok,

    input    [15:0] main_data,
    output          main_cs,
    output   [18:1] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
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

    input    [ 7:0] upd_data,
    output          upd_cs,
    output   [16:0] upd_addr,
    input           upd_ok,

    input    [15:0] title_data,
    output          title_cs,
    output   [18:1] title_addr,
    input           title_ok,

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
    output   [20:2] lyro_addr,
    input           lyro_ok
