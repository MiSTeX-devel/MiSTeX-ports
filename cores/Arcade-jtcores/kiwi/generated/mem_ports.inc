
    input cen1p5, cen3, cen6, dummy12_cen, // 12000000 = 48000000*1/4 Hz 

    // Audio channels
    
    output signed [15:0] fm,
    output [ 9:0] psg,
    output signed [ 7:0] pcm,
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
    output   [14:0] bram_addr,
    output   [7:0] bram_din,
    input   [7:0] bram_dout,
    output    bram_we,
    // Buses to BRAM

    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [16:0] main_addr,
    input           main_ok,

    input    [ 7:0] sub_data,
    output          sub_cs,
    output   [15:0] sub_addr,
    input           sub_ok,

    input    [ 7:0] audiocpu_data,
    output          audiocpu_cs,
    output   [16:0] audiocpu_addr,
    input           audiocpu_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [15:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] scr_data,
    output          scr_cs,
    output   [20:2] scr_addr,
    input           scr_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [20:2] obj_addr,
    input           obj_ok
