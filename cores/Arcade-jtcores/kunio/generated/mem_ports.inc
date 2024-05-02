
    input cen1p5, cen3, // 3000000 = 24000000*1/8 Hz 

    // Audio channels
    
    output signed [15:0] fm,
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
    output    gfx_cs,
    output   [10:0] mcu_addr,
    input   [7:0] mcu_data,
    // Buses to BRAM

    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [15:0] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [16:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] char_data,
    output   [14:2] char_addr,
    input           char_ok,

    input    [31:0] scr_data,
    output   [17:2] scr_addr,
    input           scr_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [18:2] obj_addr,
    input           obj_ok,

    input    [31:0] dummy_data,
    output          dummy_cs,
    output   [10:2] dummy_addr,
    input           dummy_ok
