
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
    output    xram_cs,
    output   [15:0] main_dout,
    // Buses to BRAM

    // Buses to SDRAM
    input    [15:0] ram_data,
    output   [17:1] ram_addr,
    output          ram_we,
    output   [ 1:0] ram_dsn,
    input           ram_ok,

    input    [15:0] main_data,
    output          main_cs,
    output   [18:1] main_addr,
    input           main_ok,

    input    [31:0] scr0ram_data,
    output          scr0ram_cs,
    output   [15:2] scr0ram_addr,
    input           scr0ram_ok,

    input    [31:0] scr1ram_data,
    output          scr1ram_cs,
    output   [15:2] scr1ram_addr,
    input           scr1ram_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [15:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [15:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] scr0rom_data,
    output          scr0rom_cs,
    output   [19:2] scr0rom_addr,
    input           scr0rom_ok,

    input    [31:0] scr1rom_data,
    output          scr1rom_cs,
    output   [19:2] scr1rom_addr,
    input           scr1rom_ok,

    input    [31:0] orom_data,
    output          orom_cs,
    output   [19:2] orom_addr,
    input           orom_ok
