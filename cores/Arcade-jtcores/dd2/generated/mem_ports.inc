
    input cen1p5, cen3, cen6, // 6000000 = 24000000*1/4 Hz 
    input cen4, cen8, // 8000000 = 24000000*1/3 Hz 
    input cen_snd, // 3579544 = 24000000*9721/65177 Hz 
    input cen_fm2, cen_fm, // 3579544 = 24000000*9721/65177 Hz 
    input cen_oki, // 1056000 = 24000000*11/250 Hz 

    // Audio channels
    
    // Sound output
`ifndef JTFRAME_STEREO
    output  signed [15:0] snd,
`else
    output  signed [15:0] snd_left, snd_right,
`endif
    output          game_led,
    output          sample,

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
    output   [1:0] cram_we,
    input   [15:0] char16_dout,
    output   [8:0] oram_addr,
    input   [7:0] oram_dout,
    output    oram_we,
    output   [10:1] cram_addr,
    input   [15:0] cram_dout,
    output   [7:0] main_dout,
    input   [7:0] obj_dout,
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

    input    [ 7:0] adpcm_data,
    output          adpcm_cs,
    output   [17:0] adpcm_addr,
    input           adpcm_ok,

    input    [31:0] char_data,
    output          char_cs,
    output   [15:2] char_addr,
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
    output   [15:0] mcu_addr,
    input           mcu_ok
