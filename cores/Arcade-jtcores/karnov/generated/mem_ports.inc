
    input cen_nc, cen_mcu, // 8000000 = 24000000*1/3 Hz 
    input cen_opn, cen_opl, // 3000000 = 24000000*1/8 Hz 

    // Audio channels
    
    output signed [15:0] opn,
    output signed [15:0] opl,
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
    output   [1:0] main_dsn,
    input   [15:0] scrram_dout,
    input   [15:0] objram_dout,
    input   [15:0] vram_dout,
    output   [10:1] scrram_addr,
    input   [15:0] scrram2main_data,
    output   [11:1] dma_addr,
    input   [15:0] objram2main_data,
    output   [11:1] objbuf_addr,
    output   [1:0] vram_we,
    input   [15:0] vram2main_data,
    output   [1:0] scrram_we,
    output   [1:0] objram_we,
    input   [15:0] objbuf_dout,
    output   [15:0] main_dout,
    output   [10:1] vram_addr,
    input   [15:0] objbuf2dma_data,
    // Buses to BRAM

    
    
    
    output   [ 1:0] dma_we, // Dual port for dma
    
    // Buses to SDRAM
    input    [15:0] main_data,
    output          main_cs,
    output   [18:1] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [15:0] snd_addr,
    input           snd_ok,

    input    [31:0] fix_data,
    output          fix_cs,
    output   [14:2] fix_addr,
    input           fix_ok,

    input    [31:0] scr_data,
    output          scr_cs,
    output   [17:2] scr_addr,
    input           scr_ok,

    input    [15:0] ram_data,
    output          ram_cs,
    output          ram_we,
    input           ram_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [18:2] obj_addr,
    input           obj_ok
