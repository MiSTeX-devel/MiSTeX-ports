
    input cen_fm2, cen_fm, // 3579545 = 49153840*455/6248 Hz 
    input cen_320, cen_640, // 640000 = 49153840*487/37403 Hz 

    // Audio channels
    output signed [15:0] fm_l,
    output signed [15:0] fm_r,
    output signed [11:0] pcm,
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
    output   [11:1] fram_addr,
    output   [1:0] vb_we,
    output   [1:0] oram_we,
    input   [7:0] pal_dout,
    output   [12:1] vram_addr,
    input   [15:0] mb_dout,
    output   [1:0] obj_we,
    input   [15:0] mo_dout,
    input   [15:0] fram_dout,
    input   [15:0] mf_dout,
    output   [12:1] scra_addr,
    input   [15:0] scra_dout,
    input   [15:0] ma_dout,
    input   [15:0] scrb_dout,
    output   [13:1] oram_addr,
    output   [11:0] pal_addr,
    output   [1:0] fx_we,
    output   [1:0] va_we,
    output   [12:1] scrb_addr,
    output   [15:0] oram_din,
    input   [15:0] oram_dout,
    output    pal_we,
    input   [7:0] mp_dout,
    // Buses to BRAM

    
    
    
    
    
    // Buses to SDRAM
    input    [15:0] ram_data,
    output          ram_cs,
    output   [13:1] ram_addr,
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

    input    [ 7:0] upd_data,
    output          upd_cs,
    output   [16:0] upd_addr,
    input           upd_ok,

    input    [31:0] lyrf_data,
    output          lyrf_cs,
    output   [13:2] lyrf_addr,
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
    output   [19:2] lyro_addr,
    input           lyro_ok
