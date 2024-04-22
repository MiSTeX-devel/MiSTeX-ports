
    input oki_cen, // 1000000 = 24000000*1/24 Hz 

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
    // Buses to BRAM

    // Buses to SDRAM
    input    [15:0] cpu_rom_data,
    output          cpu_rom_cs,
    output   [18:1] cpu_rom_addr,
    input           cpu_rom_ok,

    input    [15:0] gfx1_rom_data,
    output          gfx1_rom_cs,
    output   [16:1] gfx1_rom_addr,
    input           gfx1_rom_ok,

    input    [15:0] gfx2_rom_data,
    output          gfx2_rom_cs,
    output   [19:1] gfx2_rom_addr,
    input           gfx2_rom_ok,

    input    [15:0] gfx3_rom_data,
    output          gfx3_rom_cs,
    output   [18:1] gfx3_rom_addr,
    input           gfx3_rom_ok,

    input    [15:0] gfx4_rom_data,
    output          gfx4_rom_cs,
    output   [18:1] gfx4_rom_addr,
    input           gfx4_rom_ok,

    input    [ 7:0] z80_rom_data,
    output          z80_rom_cs,
    output   [12:0] z80_rom_addr,
    input           z80_rom_ok,

    input    [ 7:0] bank_rom_data,
    output          bank_rom_cs,
    output   [15:0] bank_rom_addr,
    input           bank_rom_ok,

    input    [ 7:0] pcm_rom_data,
    output          pcm_rom_cs,
    output   [16:0] pcm_rom_addr,
    input           pcm_rom_ok
