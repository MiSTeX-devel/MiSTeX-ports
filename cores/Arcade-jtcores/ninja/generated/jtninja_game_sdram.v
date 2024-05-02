// jtninja_game_sdram.v is automatically generated by JTFRAME
// Do not modify it
// Do not add it to git

`ifndef JTFRAME_COLORW
`define JTFRAME_COLORW 4
`endif

`ifndef JTFRAME_BUTTONS
`define JTFRAME_BUTTONS 2
`endif

module jtninja_game_sdram(
    `include "jtframe_common_ports.inc"
    `include "jtframe_mem_ports.inc"
);

/* verilator lint_off WIDTH */
localparam [25:0] BA1_START  =`ifdef JTFRAME_BA1_START  `JTFRAME_BA1_START  `else 26'd0 `endif;
localparam [25:0] BA2_START  =`ifdef JTFRAME_BA2_START  `JTFRAME_BA2_START  `else 26'd0 `endif;
localparam [25:0] BA3_START  =`ifdef JTFRAME_BA3_START  `JTFRAME_BA3_START  `else 26'd0 `endif;
localparam [25:0] PROM_START =`ifdef JTFRAME_PROM_START `JTFRAME_PROM_START `else 26'd0 `endif;
localparam [25:0] HEADER_LEN =`ifdef JTFRAME_HEADER     `JTFRAME_HEADER     `else 26'd0 `endif;
/* verilator lint_on WIDTH */


parameter B0_OFFSET = 22'h2000;
parameter B1_OFFSET = 22'h4000;
parameter B2_OFFSET = 22'h6000;
parameter GFX2_OFFSET = `GFX2_OFFSET;
parameter GFX3_OFFSET = `GFX3_OFFSET;
parameter MCU_OFFSET = `MCU_OFFSET;
parameter SND_OFFSET = (`SND_START-`JTFRAME_BA1_START)>>1;
parameter PCM_OFFSET = (`PCM_START-`JTFRAME_BA1_START)>>1;

`ifndef JTFRAME_IOCTL_RD
wire ioctl_ram = 0;
`endif
// Audio channels 
wire signed [15:0] opn;
wire signed [15:0] opl;
wire [ 9:0] psg;
wire signed [13:0] pcm;
wire mute;
// Additional ports
wire [1:0] dsn;
wire [15:0] main_dout;

// BRAM buses
// SDRAM buses

wire [15:1] ram_addr;
wire [15:0] ram_data;
wire        ram_cs, ram_ok;
wire        ram_we;
wire [15:0] ram_din;
wire [ 1:0] ram_dsn;

wire [13:1] ba2mcu_addr;
wire [15:0] ba2mcu_data;
wire        ba2mcu_cs, ba2mcu_ok;
wire        ba2mcu_we;
wire [15:0] ba2mcu_din;
wire [ 1:0] ba2mcu_dsn;

wire [13:1] b0ram_addr;
wire [15:0] b0ram_data;
wire        b0ram_cs, b0ram_ok;
wire [13:1] b1ram_addr;
wire [15:0] b1ram_data;
wire        b1ram_cs, b1ram_ok;
wire [13:1] b2ram_addr;
wire [15:0] b2ram_data;
wire        b2ram_cs, b2ram_ok;
wire [18:1] main_addr;
wire [15:0] main_data;
wire        main_cs, main_ok;
wire [15:0] snd_addr;
wire [ 7:0] snd_data;
wire        snd_cs, snd_ok;
wire [17:0] adpcm_addr;
wire [ 7:0] adpcm_data;
wire        adpcm_cs, adpcm_ok;
wire [18:2] b0rom_addr;
wire [31:0] b0rom_data;
wire        b0rom_cs, b0rom_ok;
wire [18:2] b1rom_addr;
wire [31:0] b1rom_data;
wire        b1rom_cs, b1rom_ok;
wire [18:2] b2rom_addr;
wire [31:0] b2rom_data;
wire        b2rom_cs, b2rom_ok;
wire [18:2] obj_addr;
wire [31:0] obj_data;
wire        obj_cs, obj_ok;
wire [15:0] mcu_addr;
wire [ 7:0] mcu_data;
wire        mcu_cs, mcu_ok;
wire        prom_we, header;
wire [21:0] raw_addr, post_addr;
wire [25:0] pre_addr, dwnld_addr, ioctl_addr_noheader;
wire [ 7:0] post_data;
wire [15:0] raw_data;
wire        pass_io;

wire gfx8_en, gfx16_en, ioctl_dwn;

assign pass_io = header | ioctl_ram;
assign ioctl_addr_noheader = `ifdef JTFRAME_HEADER header ? ioctl_addr : ioctl_addr - HEADER_LEN `else ioctl_addr `endif ;

wire rst_h, rst24_h, rst48_h, hold_rst;
/* verilator tracing_off */
jtframe_rsthold u_hold(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .hold   ( hold_rst  ),
    .rst_h  ( rst_h     )
`ifdef JTFRAME_CLK24 ,
    .rst24  ( rst24     ),
    .clk24  ( clk24     ),
    .rst24_h( rst24_h   )
`endif
`ifdef JTFRAME_CLK48 ,
    .rst48  ( rst48     ),
    .clk48  ( clk48     ),
    .rst48_h( rst48_h   )
`endif
);
/* verilator tracing_on */
jtcop_game u_game(
    .rst        ( rst_h     ),
    .clk        ( clk       ),
`ifdef JTFRAME_CLK24
    .rst24      ( rst24_h   ),
    .clk24      ( clk24     ),
`endif
`ifdef JTFRAME_CLK48
    .rst48      ( rst48_h   ),
    .clk48      ( clk48     ),
`endif
    // Audio channels
    .opn     ( opn      ),.opl     ( opl      ),.psg     ( psg      ),.pcm     ( pcm      ),
    
    .snd_en         ( snd_en        ),
    .pxl2_cen       ( pxl2_cen      ),
    .pxl_cen        ( pxl_cen       ),
    .red            ( red           ),
    .green          ( green         ),
    .blue           ( blue          ),
    .LHBL           ( LHBL          ),
    .LVBL           ( LVBL          ),
    .HS             ( HS            ),
    .VS             ( VS            ),
    // cabinet I/O
    .cab_1p   ( cab_1p  ),
    .coin     ( coin    ),
    .joystick1    ( joystick1        ), .joystick2    ( joystick2        ), `ifdef JTFRAME_4PLAYERS
    .joystick3    ( joystick3        ), .joystick4    ( joystick4        ), `endif `ifdef JTFRAME_MOUSE
    .mouse_1p     ( mouse_1p         ), .mouse_2p     ( mouse_2p         ), `endif `ifdef JTFRAME_SPINNER
    .spinner_1p   ( spinner_1p       ), .spinner_2p   ( spinner_2p       ), `endif `ifdef JTFRAME_ANALOG
    .joyana_l1    ( joyana_l1        ), .joyana_l2    ( joyana_l2        ), `ifdef JTFRAME_ANALOG_DUAL
    .joyana_r1    ( joyana_r1        ), .joyana_r2    ( joyana_r2        ), `endif `ifdef JTFRAME_4PLAYERS
    .joyana_l3    ( joyana_l3        ), .joyana_l4    ( joyana_l4        ), `ifdef JTFRAME_ANALOG_DUAL
    .joyana_r3    ( joyana_r3        ), .joyana_r4    ( joyana_r4        ), `endif `endif `endif `ifdef JTFRAME_DIAL
    .dial_x       ( dial_x           ), .dial_y       ( dial_y           ), `endif
    // DIP switches
    .status         ( status        ),
    .dipsw          ( dipsw         ),
    .service        ( service       ),
    .tilt           ( tilt          ),
    .dip_pause      ( dip_pause     ),
    .dip_flip       ( dip_flip      ),
    .dip_test       ( dip_test      ),
    .dip_fxlevel    ( dip_fxlevel   ),
    .enable_psg     ( enable_psg    ),
    .enable_fm      ( enable_fm     ),
    // Ports declared in mem.yaml
    .dsn   ( dsn ),
    .main_dout   ( main_dout ),
    // Memory interface - SDRAM
    .ram_addr ( ram_addr ),
    .ram_cs   ( ram_cs   ),
    .ram_ok   ( ram_ok   ),
    .ram_data ( ram_data ),
    .ram_we   ( ram_we   ),
    
    
    
    .ba2mcu_addr ( ba2mcu_addr ),
    .ba2mcu_cs   ( ba2mcu_cs   ),
    .ba2mcu_ok   ( ba2mcu_ok   ),
    .ba2mcu_data ( ba2mcu_data ),
    .ba2mcu_we   ( ba2mcu_we   ),
    .ba2mcu_dsn  ( ba2mcu_dsn  ),
    .ba2mcu_din  ( ba2mcu_din  ),
    
    .b0ram_addr ( b0ram_addr ),
    .b0ram_cs   ( b0ram_cs   ),
    .b0ram_ok   ( b0ram_ok   ),
    .b0ram_data ( b0ram_data ),
    
    .b1ram_addr ( b1ram_addr ),
    .b1ram_cs   ( b1ram_cs   ),
    .b1ram_ok   ( b1ram_ok   ),
    .b1ram_data ( b1ram_data ),
    
    .b2ram_addr ( b2ram_addr ),
    .b2ram_cs   ( b2ram_cs   ),
    .b2ram_ok   ( b2ram_ok   ),
    .b2ram_data ( b2ram_data ),
    
    .main_addr ( main_addr ),
    .main_cs   ( main_cs   ),
    .main_ok   ( main_ok   ),
    .main_data ( main_data ),
    
    .snd_addr ( snd_addr ),
    .snd_cs   ( snd_cs   ),
    .snd_ok   ( snd_ok   ),
    .snd_data ( snd_data ),
    
    .adpcm_addr ( adpcm_addr ),
    .adpcm_cs   ( adpcm_cs   ),
    .adpcm_ok   ( adpcm_ok   ),
    .adpcm_data ( adpcm_data ),
    
    .b0rom_addr ( b0rom_addr ),
    .b0rom_cs   ( b0rom_cs   ),
    .b0rom_ok   ( b0rom_ok   ),
    .b0rom_data ( b0rom_data ),
    
    .b1rom_addr ( b1rom_addr ),
    .b1rom_cs   ( b1rom_cs   ),
    .b1rom_ok   ( b1rom_ok   ),
    .b1rom_data ( b1rom_data ),
    
    .b2rom_addr ( b2rom_addr ),
    .b2rom_cs   ( b2rom_cs   ),
    .b2rom_ok   ( b2rom_ok   ),
    .b2rom_data ( b2rom_data ),
    
    .obj_addr ( obj_addr ),
    .obj_cs   ( obj_cs   ),
    .obj_ok   ( obj_ok   ),
    .obj_data ( obj_data ),
    
    .mcu_addr ( mcu_addr ),
    .mcu_cs   ( mcu_cs   ),
    .mcu_ok   ( mcu_ok   ),
    .mcu_data ( mcu_data ),
    
    // Memory interface - BRAM

    // PROM writting
    .ioctl_addr   ( pass_io ? ioctl_addr       : ioctl_addr_noheader  ),
    .prog_addr    ( pass_io ? ioctl_addr[21:0] : raw_addr      ),
    .prog_data    ( pass_io ? ioctl_dout       : raw_data[7:0] ),
    .prog_we      ( pass_io ? ioctl_wr         : prog_we       ),
    .prog_ba      ( prog_ba        ), // prog_ba supplied in case it helps re-mapping addresses
`ifdef JTFRAME_PROM_START
    .prom_we      ( prom_we        ),
`endif
    // SDRAM address mapper during downloading
    .post_addr    ( post_addr      ),
    .post_data    ( post_data      ),
`ifdef JTFRAME_HEADER
    .header       ( header         ),
`endif
`ifdef JTFRAME_IOCTL_RD
    .ioctl_ram    ( ioctl_ram      ),
    .ioctl_din    ( ioctl_din      ),
    .ioctl_dout   ( ioctl_dout     ),
    .ioctl_wr     ( ioctl_wr       ), `endif
    .ioctl_cart   ( ioctl_cart     ),
    // Debug
    .debug_bus    ( debug_bus      ),
    .debug_view   ( debug_view     ),
`ifdef JTFRAME_STATUS
    .st_addr      ( st_addr        ),
    .st_dout      ( st_dout        ),
`endif
`ifdef JTFRAME_LF_BUFFER
    .game_vrender( game_vrender  ),
    .game_hdump  ( game_hdump    ),
    .ln_addr     ( ln_addr       ),
    .ln_data     ( ln_data       ),
    .ln_done     ( ln_done       ),
    .ln_hs       ( ln_hs         ),
    .ln_pxl      ( ln_pxl        ),
    .ln_v        ( ln_v          ),
    .ln_we       ( ln_we         ),
`endif
    .gfx_en      ( gfx_en        )
);
/* verilator tracing_off */
assign dwnld_busy = ioctl_rom | prom_we; // prom_we is really just for sims
assign dwnld_addr = ioctl_addr;
assign prog_addr = post_addr;
assign prog_data = {2{post_data}};
assign gfx8_en   = 0;
assign gfx16_en  = 0;
assign ioctl_dwn = ioctl_rom | ioctl_cart;
`ifdef VERILATOR_KEEP_SDRAM /* verilator tracing_on */ `else /* verilator tracing_off */ `endif
jtframe_dwnld #(
`ifdef JTFRAME_HEADER
    .HEADER    ( `JTFRAME_HEADER   ),
`endif
`ifdef JTFRAME_BA1_START
    .BA1_START ( BA1_START ),
`endif
`ifdef JTFRAME_BA2_START
    .BA2_START ( BA2_START ),
`endif
`ifdef JTFRAME_BA3_START
    .BA3_START ( BA3_START ),
`endif
`ifdef JTFRAME_PROM_START
    .PROM_START( PROM_START ),
`endif
    .SWAB      ( 1),
    .GFX8B0    ( 0),
    .GFX16B0   ( 0)
) u_dwnld(
    .clk          ( clk            ),
    .ioctl_rom    ( ioctl_dwn      ),
    .ioctl_addr   ( dwnld_addr     ),
    .ioctl_dout   ( ioctl_dout     ),
    .ioctl_wr     ( ioctl_wr       ),
    .gfx8_en      ( gfx8_en        ),
    .gfx16_en     ( gfx16_en       ),
    .prog_addr    ( raw_addr       ),
    .prog_data    ( raw_data       ),
    .prog_mask    ( prog_mask      ), // active low
    .prog_we      ( prog_we        ),
    .prog_rd      ( prog_rd        ),
    .prog_ba      ( prog_ba        ),
    .prom_we      ( prom_we        ),
    .header       ( header         ),
    .sdram_ack    ( prog_ack       )
);
`ifdef VERILATOR_KEEP_SDRAM /* verilator tracing_on */ `else /* verilator tracing_off */ `endif



jtframe_ram2_5slots #(
    // ram
    .SLOT0_AW(15),
    .SLOT0_DW(16), 
    // ba2mcu
    .SLOT1_AW(13),
    .SLOT1_DW(16), 
    // b0ram
    .SLOT2_OFFSET(B0_OFFSET[21:0]),
    .SLOT2_AW(13),
    .SLOT2_DW(16), 
    // b1ram
    .SLOT3_OFFSET(B1_OFFSET[21:0]),
    .SLOT3_AW(13),
    .SLOT3_DW(16), 
    // b2ram
    .SLOT4_OFFSET(B2_OFFSET[21:0]),
    .SLOT4_AW(13),
    .SLOT4_DW(16)
`ifdef JTFRAME_BA2_LEN
    ,.SLOT2_DOUBLE(1)
    ,.SLOT3_DOUBLE(1)
    ,.SLOT4_DOUBLE(1)
`endif
) u_bank0(
    .rst         ( rst        ),
    .clk         ( clk        ),
    
    .slot0_addr  ( ram_addr  ),
    .hold_rst    ( hold_rst        ), 
    .slot0_wen   ( ram_we    ),
    .slot0_din   ( main_dout   ),
    .slot0_wrmask( dsn   ),
    .slot0_offset( 22'd0 ),
    .slot0_dout  ( ram_data  ),
    .slot0_cs    ( ram_cs    ),
    .slot0_ok    ( ram_ok    ),
    
    .slot1_addr  ( ba2mcu_addr  ),
    .slot1_wen   ( ba2mcu_we    ),
    .slot1_din   ( ba2mcu_din   ),
    .slot1_wrmask( ba2mcu_dsn   ),
    .slot1_offset( B2_OFFSET[21:0] ),
    .slot1_dout  ( ba2mcu_data  ),
    .slot1_cs    ( ba2mcu_cs    ),
    .slot1_ok    ( ba2mcu_ok    ),
    
    .slot2_addr  ( b0ram_addr  ),
    .slot2_clr   ( 1'b0       ), // only 1'b0 supported in mem.yaml
    .slot2_dout  ( b0ram_data  ),
    .slot2_cs    ( b0ram_cs    ),
    .slot2_ok    ( b0ram_ok    ),
    
    .slot3_addr  ( b1ram_addr  ),
    .slot3_clr   ( 1'b0       ), // only 1'b0 supported in mem.yaml
    .slot3_dout  ( b1ram_data  ),
    .slot3_cs    ( b1ram_cs    ),
    .slot3_ok    ( b1ram_ok    ),
    
    .slot4_addr  ( b2ram_addr  ),
    .slot4_clr   ( 1'b0       ), // only 1'b0 supported in mem.yaml
    .slot4_dout  ( b2ram_data  ),
    .slot4_cs    ( b2ram_cs    ),
    .slot4_ok    ( b2ram_ok    ),
    
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[0]  ),
    .sdram_rd    ( ba_rd[0]   ),
    .sdram_addr  ( ba0_addr   ),
    .sdram_wr    ( ba_wr[0]   ),
    .sdram_wrmask( ba0_dsn    ),
    .data_write  ( ba0_din    ),
    .data_dst    ( ba_dst[0]  ),
    .data_rdy    ( ba_rdy[0]  ),
    .data_read   ( data_read  )
);
jtframe_rom_3slots #(
    // main
    .SLOT0_AW(18),
    .SLOT0_DW(16), 
    // snd
    .SLOT1_OFFSET(SND_OFFSET[21:0]),
    .SLOT1_AW(16),
    .SLOT1_DW( 8), 
    // adpcm
    .SLOT2_OFFSET(PCM_OFFSET[21:0]),
    .SLOT2_AW(18),
    .SLOT2_DW( 8)
`ifdef JTFRAME_BA2_LEN
    ,.SLOT0_DOUBLE(1)
    ,.SLOT1_DOUBLE(1)
    ,.SLOT2_DOUBLE(1)
`endif
) u_bank1(
    .rst         ( rst        ),
    .clk         ( clk        ),
    
    .slot0_addr  ( main_addr  ),
    .slot0_dout  ( main_data  ),
    .slot0_cs    ( main_cs    ),
    .slot0_ok    ( main_ok    ),
    
    .slot1_addr  ( snd_addr  ),
    .slot1_dout  ( snd_data  ),
    .slot1_cs    ( snd_cs    ),
    .slot1_ok    ( snd_ok    ),
    
    .slot2_addr  ( adpcm_addr  ),
    .slot2_dout  ( adpcm_data  ),
    .slot2_cs    ( adpcm_cs    ),
    .slot2_ok    ( adpcm_ok    ),
    
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[1]  ),
    .sdram_rd    ( ba_rd[1]   ),
    .sdram_addr  ( ba1_addr   ),
    .data_dst    ( ba_dst[1]  ),
    .data_rdy    ( ba_rdy[1]  ),
    .data_read   ( data_read  )
);
assign ba_wr[1] = 0;
assign ba1_din  = 0;
assign ba1_dsn  = 3;
jtframe_rom_3slots #(
    // b0rom
    .SLOT0_AW(18),
    .SLOT0_DW(32), 
    // b1rom
    .SLOT1_OFFSET(GFX2_OFFSET[21:0]),
    .SLOT1_AW(18),
    .SLOT1_DW(32), 
    // b2rom
    .SLOT2_OFFSET(GFX3_OFFSET[21:0]),
    .SLOT2_AW(18),
    .SLOT2_DW(32)
`ifdef JTFRAME_BA2_LEN
    ,.SLOT0_DOUBLE(1)
    ,.SLOT1_DOUBLE(1)
    ,.SLOT2_DOUBLE(1)
`endif
) u_bank2(
    .rst         ( rst        ),
    .clk         ( clk        ),
    
    .slot0_addr  ( { b0rom_addr, 1'b0 } ),
    .slot0_dout  ( b0rom_data  ),
    .slot0_cs    ( b0rom_cs    ),
    .slot0_ok    ( b0rom_ok    ),
    
    .slot1_addr  ( { b1rom_addr, 1'b0 } ),
    .slot1_dout  ( b1rom_data  ),
    .slot1_cs    ( b1rom_cs    ),
    .slot1_ok    ( b1rom_ok    ),
    
    .slot2_addr  ( { b2rom_addr, 1'b0 } ),
    .slot2_dout  ( b2rom_data  ),
    .slot2_cs    ( b2rom_cs    ),
    .slot2_ok    ( b2rom_ok    ),
    
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[2]  ),
    .sdram_rd    ( ba_rd[2]   ),
    .sdram_addr  ( ba2_addr   ),
    .data_dst    ( ba_dst[2]  ),
    .data_rdy    ( ba_rdy[2]  ),
    .data_read   ( data_read  )
);
assign ba_wr[2] = 0;
assign ba2_din  = 0;
assign ba2_dsn  = 3;
jtframe_rom_2slots #(
    // obj
    .SLOT0_AW(18),
    .SLOT0_DW(32), 
    // mcu
    .SLOT1_OFFSET(MCU_OFFSET[21:0]),
    .SLOT1_AW(16),
    .SLOT1_DW( 8)
`ifdef JTFRAME_BA2_LEN
    ,.SLOT0_DOUBLE(1)
    ,.SLOT1_DOUBLE(1)
`endif
) u_bank3(
    .rst         ( rst        ),
    .clk         ( clk        ),
    
    .slot0_addr  ( { obj_addr, 1'b0 } ),
    .slot0_dout  ( obj_data  ),
    .slot0_cs    ( obj_cs    ),
    .slot0_ok    ( obj_ok    ),
    
    .slot1_addr  ( mcu_addr  ),
    .slot1_dout  ( mcu_data  ),
    .slot1_cs    ( mcu_cs    ),
    .slot1_ok    ( mcu_ok    ),
    
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[3]  ),
    .sdram_rd    ( ba_rd[3]   ),
    .sdram_addr  ( ba3_addr   ),
    .data_dst    ( ba_dst[3]  ),
    .data_rdy    ( ba_rdy[3]  ),
    .data_read   ( data_read  )
);
assign ba_wr[3] = 0;
assign ba3_din  = 0;
assign ba3_dsn  = 3;




`ifndef NOSOUND/* verilator tracing_on */
assign mute=0;
jtframe_rcmix #(
    .W0(16),
    .W1(16),
    .W2(10),
    .W3(14),
    .FIR3("fir_192k_4k.hex"),
    .STEREO0( 0),
    .STEREO1( 0),
    .STEREO2( 0),
    .STEREO3( 0),
    .STEREO4( 0),
    .STEREO5( 0),
    .DCRM0  ( 0),
    .DCRM1  ( 0),
    .DCRM2  ( 1),
    .DCRM3  ( 0),
    .DCRM4  ( 0),
    .DCRM5  ( 0),
    .STEREO ( 0),
    // Fractional cen for 192kHz
    .FRACW( 9), .FRACN(1), .FRACM(250)
) u_rcmix(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .mute   ( mute      ),
    .sample ( sample    ),
    .ch_en  ( snd_en    ),
    .gpole  ( 8'h86 ),  // 19894 Hz 
    .ch0    ( opn ),
    .ch1    ( opl ),
    .ch2    ( psg ),
    .ch3    ( pcm ),
    .ch4    ( 16'd0 ),
    .ch5    ( 16'd0 ),
    .p0     ( 16'h0), // 0 Hz, 0 Hz 
    .p1     ( 16'h0), // 0 Hz, 0 Hz 
    .p2     ( 16'h0), // 0 Hz, 0 Hz 
    .p3     ( 16'h00), // 0 Hz, 0 Hz 
    .p4     ( 16'h0), 
    .p5     ( 16'h0), 
    .g0     ( 8'h16 ), // opn
    .g1     ( 8'h16 ), // opl
    .g2     ( 8'h1B ), // psg
    .g3     ( 8'h80 ), // pcm
    .g4     ( 8'h00 ), 
    .g5     ( 8'h00 ), 
    .mixed(snd),
    .peak ( game_led ),
    .vu   ( snd_vu   )
);
`else
assign snd=0;
assign snd_vu   = 0;
assign game_led = 0;
wire ncs;
jtframe_frac_cen #(.WC(9)) u_cen192(
    .clk    ( clk       ),
    .n      ( 1 ),
    .m      ( 250 ),
    .cen    ( {  ncs,sample }  ), // sample is always 192 kHz
    .cenb   (                  )
);
`endif
endmodule
