
    input cen_fm2, cen_fm, // 3579545 = 49153840*455/6248 Hz 

    // Audio channels
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,
    output signed [10:0] pcm,output signed [12:0] cus30_l,
    output signed [12:0] cus30_r,
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
    output   [12:0] rgb_addr,
    input   [7:0] mask_data,
    output   [12:0] sndram_addr,
    output   [1:0] oram_we,
    output   [7:0] mcu_dout,
    output   [11:1] obus_addr,
    input   [15:0] obus_dout,
    output   [10:0] eerom_addr,
    input   [15:0] vram_dout,
    output   [15:0] oram_din,
    input   [7:0] bpal_dout,
    input   [7:0] eerom_dout,
    output   [16:0] mask_addr,
    output    ram_we,
    output   [14:1] tmap_addr,
    input   [7:0] green_dout,
    output    eerom_we,
    output   [14:1] vram_addr,
    output   [7:0] sndram_din,
    input   [7:0] red_dout,
    input   [7:0] ram_dout,
    output   [11:1] oram_addr,
    input   [7:0] gpal_dout,
    output    sndram_we,
    input   [15:0] oram_dout,
    input   [7:0] rpal_dout,
    output   [14:0] ram_addr,
    output   [7:0] ram_din,
    input   [7:0] sndram_dout,
    output   [15:0] bdout16,
    output   [12:0] pal_addr,
    input   [7:0] blue_dout,
    input   [15:0] tmap_dout,
    // Buses to BRAM

    
    
    output   [ 1:0] vram_we, // Dual port for vram
    
    
    output   [ 1:0] obus_we, // Dual port for obus
    
    output          rpal_we, // Dual port for rpal
    
    output          gpal_we, // Dual port for gpal
    
    output          bpal_we, // Dual port for bpal
    
    
    // Buses to SDRAM
    input    [ 7:0] main_data,
    output          main_cs,
    output   [21:0] main_addr,
    input           main_ok,

    input    [ 7:0] sub_data,
    output          sub_cs,
    output   [21:0] sub_addr,
    input           sub_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [16:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [19:0] pcm_addr,
    input           pcm_ok,

    input    [ 7:0] scr_data,
    output          scr_cs,
    output   [19:0] scr_addr,
    input           scr_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [19:2] obj_addr,
    input           obj_ok
