
    input cen12, cen24, // 24000000 = 48000000*1/2 Hz 

    // Audio channels
    
    output signed [15:0] fm,
    output signed [11:0] scc,
    output signed [11:0] pcm_a,
    output signed [11:0] pcm_b,
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
    output   [12:0] ram_addr,
    output   [7:0] ram_din,
    input   [7:0] ram_dout,
    output    ram_we,
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

    input    [15:0] gfx1_data,
    output          gfx1_cs,
    output   [19:1] gfx1_addr,
    input           gfx1_ok,

    input    [15:0] gfx2_data,
    output          gfx2_cs,
    output   [19:1] gfx2_addr,
    input           gfx2_ok
