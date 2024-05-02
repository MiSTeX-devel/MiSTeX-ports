
    input mcu_cen6, mcu_cen12, // 12000000 = 48000000*1/4 Hz 

    input cen0p75, cen1p5, cen3, cen6, // 6000000 = 24000000*1/4 Hz 
    input cen_fm2, cen_fm, // 3579544 = 24000000*9721/65177 Hz 

    // Audio channels
    
    output signed [11:0] pcm_a,
    output pcm_a_rcen,
    output signed [11:0] pcm_b,
    output pcm_b_rcen,output signed [15:0] fm_l,
    output signed [15:0] fm_r,
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
    output   [7:0] main_dout,
    input   [7:0] obj_dout,
    input   [15:0] cram_dout,
    output   [1:0] cram_we,
    input   [7:0] oram_dout,
    output    oram_we,
    output   [10:1] cram_addr,
    input   [15:0] char16_dout,
    output   [8:0] oram_addr,
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

    input    [ 7:0] adpcm0_data,
    output          adpcm0_cs,
    output   [15:0] adpcm0_addr,
    input           adpcm0_ok,

    input    [ 7:0] adpcm1_data,
    output          adpcm1_cs,
    output   [15:0] adpcm1_addr,
    input           adpcm1_ok,

    input    [31:0] char_data,
    output          char_cs,
    output   [14:2] char_addr,
    input           char_ok,

    input    [15:0] scr_data,
    output          scr_cs,
    output   [17:1] scr_addr,
    input           scr_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [19:2] obj_addr,
    input           obj_ok,

    input    [ 7:0] mcu_data,
    output          mcu_cs,
    output   [13:0] mcu_addr,
    input           mcu_ok
