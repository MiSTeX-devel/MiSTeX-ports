
    input cen3, cen6, // 6000000 = 48000000*1/8 Hz 
    input cen4, // 4000000 = 48000000*1/12 Hz 

    // Audio channels
    
    output signed [15:0] fm03,
    output signed [15:0] fm26,
    output [ 9:0] psg,
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
    output   [11:0] mcu_addr,
    input   [7:0] mcu_data,
    // Buses to BRAM

    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [17:0] main_addr,
    input           main_ok,

    input    [ 7:0] sub_data,
    output          sub_cs,
    output   [14:0] sub_addr,
    input           sub_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [14:0] snd_addr,
    input           snd_ok,

    input    [31:0] gfx_data,
    output          gfx_cs,
    output   [18:2] gfx_addr,
    input           gfx_ok
