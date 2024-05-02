
    input cen_fm2, cen_fm, cen_pcm, // 7999999 = 50318176*7851/49381 Hz 
    input cen_nc, cen_snd, // 5000000 = 50318176*6443/64840 Hz 

    // Audio channels
    output mute,
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,output signed [15:0] pcm_l,
    output signed [15:0] pcm_r,
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
    input   [15:0] rd0_data,
    output   [14:1] rd1_addr,
    input   [15:0] rd1_data,
    output    gfx_cs,
    output   [14:1] rd0_addr,
    // Buses to BRAM

    
    
    // Buses to SDRAM
    input    [15:0] xram_data,
    output          xram_cs,
    output   [16:1] xram_addr,
    output          xram_we,
    output   [15:0] xram_din,
    output   [ 1:0] xram_dsn,
    input           xram_ok,

    input    [15:0] subram_data,
    output          subram_cs,
    output   [14:1] subram_addr,
    output          subram_we,
    output   [15:0] subram_din,
    output   [ 1:0] subram_dsn,
    input           subram_ok,

    input    [15:0] main_data,
    output          main_cs,
    output   [18:1] main_addr,
    input           main_ok,

    input    [15:0] map1_data,
    output   [15:1] map1_addr,
    input           map1_ok,

    input    [15:0] map2_data,
    output   [15:1] map2_addr,
    input           map2_ok,

    input    [15:0] subrom_data,
    output          subrom_cs,
    output   [18:1] subrom_addr,
    input           subrom_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [15:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [18:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] char_data,
    output   [13:2] char_addr,
    input           char_ok,

    input    [31:0] scr1_data,
    output   [17:2] scr1_addr,
    input           scr1_ok,

    input    [31:0] scr2_data,
    output   [17:2] scr2_addr,
    input           scr2_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [19:2] obj_addr,
    input           obj_ok
