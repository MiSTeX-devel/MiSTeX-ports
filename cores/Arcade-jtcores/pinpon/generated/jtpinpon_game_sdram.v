// jtpinpon_game_sdram.v is automatically generated by JTFRAME
// Do not modify it
// Do not add it to git

`ifndef JTFRAME_COLORW
`define JTFRAME_COLORW 4
`endif

`ifndef JTFRAME_BUTTONS
`define JTFRAME_BUTTONS 2
`endif

module jtpinpon_game_sdram(
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


parameter SCR_OFFSET = `SCR_START >> 1;
parameter OBJ_OFFSET = `OBJ_START >> 1;

`ifndef JTFRAME_IOCTL_RD
wire ioctl_ram = 0;
`endif
// Audio channels 
wire signed [10:0] ti1;
wire mute;
// Additional ports

// BRAM buses
// SDRAM buses

wire [12:1] scr_addr;
wire [15:0] scr_data;
wire        scr_cs, scr_ok;
wire [12:2] objrom_addr;
wire [31:0] objrom_data;
wire        objrom_cs, objrom_ok;
wire [14:0] main_addr;
wire [ 7:0] main_data;
wire        main_cs, main_ok;
wire        prom_we, header;
wire [21:0] raw_addr, post_addr;
wire [25:0] pre_addr, dwnld_addr, ioctl_addr_noheader;
wire [ 7:0] post_data;
wire [15:0] raw_data;
wire        pass_io;
// Clock enable signals
wire cpu4_cen; 
wire ti1_cen; 
wire ti2_cen; 
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
jtpinpon_game u_game(
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
    .ti1     ( ti1      ),
    
    .snd_en         ( snd_en        ),
    .cpu4_cen    ( cpu4_cen    ), 
    .ti1_cen    ( ti1_cen    ), 
    .ti2_cen    ( ti2_cen    ), 

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
    // Memory interface - SDRAM
    .scr_addr ( scr_addr ),
    .scr_ok   ( scr_ok   ),
    .scr_data ( scr_data ),
    
    .objrom_addr ( objrom_addr ),
    .objrom_cs   ( objrom_cs   ),
    .objrom_ok   ( objrom_ok   ),
    .objrom_data ( objrom_data ),
    
    .main_addr ( main_addr ),
    .main_cs   ( main_cs   ),
    .main_ok   ( main_ok   ),
    .main_data ( main_data ),
    
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
    .pre_addr     ( pre_addr       ),
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
assign dwnld_addr = pre_addr;
assign prog_addr = raw_addr;
assign prog_data = raw_data;
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



jtframe_rom_3slots #(
    // scr
    .SLOT0_OFFSET(SCR_OFFSET[21:0]),
    .SLOT0_AW(12),
    .SLOT0_DW(16), 
    // objrom
    .SLOT1_OFFSET(OBJ_OFFSET[21:0]),
    .SLOT1_AW(12),
    .SLOT1_DW(32), 
    // main
    .SLOT2_AW(15),
    .SLOT2_DW( 8)
`ifdef JTFRAME_BA2_LEN
    ,.SLOT0_DOUBLE(1)
    ,.SLOT1_DOUBLE(1)
    ,.SLOT2_DOUBLE(1)
`endif
) u_bank0(
    .rst         ( rst        ),
    .clk         ( clk        ),
    
    .slot0_addr  ( scr_addr  ),
    .slot0_dout  ( scr_data  ),
    .slot0_cs    ( LVBL    ),
    .slot0_ok    ( scr_ok    ),
    
    .slot1_addr  ( { objrom_addr, 1'b0 } ),
    .slot1_dout  ( objrom_data  ),
    .slot1_cs    ( objrom_cs    ),
    .slot1_ok    ( objrom_ok    ),
    
    .slot2_addr  ( main_addr  ),
    .slot2_dout  ( main_data  ),
    .slot2_cs    ( main_cs    ),
    .slot2_ok    ( main_ok    ),
    
    // SDRAM controller interface
    .sdram_ack   ( ba_ack[0]  ),
    .sdram_rd    ( ba_rd[0]   ),
    .sdram_addr  ( ba0_addr   ),
    .data_dst    ( ba_dst[0]  ),
    .data_rdy    ( ba_rdy[0]  ),
    .data_read   ( data_read  )
);
assign ba_wr[0] = 0;
assign ba0_din  = 0;
assign ba0_dsn  = 3;
assign hold_rst=0;
assign ba1_addr = 0;
assign ba_rd[1] = 0;
assign ba_wr[1] = 0;
assign ba1_dsn  = 3;
assign ba1_din  = 0;
assign ba2_addr = 0;
assign ba_rd[2] = 0;
assign ba_wr[2] = 0;
assign ba2_dsn  = 3;
assign ba2_din  = 0;
assign ba3_addr = 0;
assign ba_rd[3] = 0;
assign ba_wr[3] = 0;
assign ba3_dsn  = 3;
assign ba3_din  = 0;



// Clock enable generation
// 6144230 = 24576920*1/4 Hz from clk24
`ifdef VERILATOR_KEEP_CEN /* verilator tracing_on */ `else /* verilator tracing_off */ `endif
jtframe_gated_cen #(.W(3),.NUM(1),.DEN(4),.MFREQ(24576)) u_cen0_clk24(
    .rst    ( rst          ),
    .clk    ( clk24 ),
    .busy   ( 1'b0    ),
    .cen    ( { ti2_cen, ti1_cen, cpu4_cen } ),
    .fave   (              ),
    .fworst (              )
); /* verilator tracing_off */

`ifndef NOSOUND/* verilator tracing_on */
assign mute=0;
jtframe_rcmix #(
    .W0(11),
    .STEREO0( 0),
    .STEREO1( 0),
    .STEREO2( 0),
    .STEREO3( 0),
    .STEREO4( 0),
    .STEREO5( 0),
    .DCRM0  ( 0),
    .DCRM1  ( 0),
    .DCRM2  ( 0),
    .DCRM3  ( 0),
    .DCRM4  ( 0),
    .DCRM5  ( 0),
    .STEREO ( 0),
    // Fractional cen for 192kHz
    .FRACW( 17), .FRACN(209), .FRACM(53506)
) u_rcmix(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .mute   ( mute      ),
    .sample ( sample    ),
    .ch_en  ( snd_en    ),
    .gpole  ( 8'hF3 ),  // 1592 Hz 
    .ch0    ( ti1 ),
    .ch1    ( 16'd0 ),
    .ch2    ( 16'd0 ),
    .ch3    ( 16'd0 ),
    .ch4    ( 16'd0 ),
    .ch5    ( 16'd0 ),
    .p0     ( 16'hEAF9), // 796 Hz, 2709 Hz 
    .p1     ( 16'h0), 
    .p2     ( 16'h0), 
    .p3     ( 16'h0), 
    .p4     ( 16'h0), 
    .p5     ( 16'h0), 
    .g0     ( 8'h80 ), // ti1
    .g1     ( 8'h00 ), 
    .g2     ( 8'h00 ), 
    .g3     ( 8'h00 ), 
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
jtframe_frac_cen #(.WC(17)) u_cen192(
    .clk    ( clk       ),
    .n      ( 209 ),
    .m      ( 53506 ),
    .cen    ( {  ncs,sample }  ), // sample is always 192 kHz
    .cenb   (                  )
);
`endif
endmodule
