//============================================================================
//  Arcade: Pacman
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output		  VGA_DISABLE,

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;
assign FB_FORCE_BLANK = 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE = 0;

wire [1:0] ar = status[15:14];

assign VIDEO_ARX = (!ar) ? ((status[2] | mod_ponp) ? 12'd2880 : 12'd2219) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] | mod_ponp) ? 12'd2219 : 12'd2880) : 12'd0;

`include "build_id.vh" 
localparam CONF_STR = {
	"A.PACMAN;;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H1H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O7,Flip Screen,Off,On;",
	"OQS,CRT H-sync Adjust,0,1,2,3,4,5,6,7;",
	"OTV,CRT V-sync Adjust,0,1,2,3,4,5,6,7;",
	"-;",
	"H2OP,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1ON,Pause when OSD is open,On,Off;",
	"P1OO,Dim video after 10s,On,Off;",
	"-;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin,Cheat,Pause;",
	"jn,A,Start,Select,R,L,X;",
	"DEFMRA,Puck Man (Japan set 1).mra;", // default MRA to be used when core is uploaded by USB blaster (debug)
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys, clk_vid;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_vid),
	.outclk_1(clk_sys),
	.locked(pll_locked)
);

reg ce_6m;
always @(posedge clk_sys) begin
	reg [1:0] div;

	div <= div + 1'd1;
	ce_6m <= !div;
end

reg ce_4m;
always @(posedge clk_sys) begin
	reg [2:0] div;

	div <= div + 1'd1;
	if(div == 5) div <= 0;
	ce_4m <= !div;
end

reg ce_1m79;
always @(posedge clk_sys) begin
	reg [3:0] div;

	div <= div + 1'd1;
	if(div == 12) div <= 0;
	ce_1m79 <= !div;
end

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

wire [15:0] joy1 = (mod_club | mod_jmpst) ? joy1a : (joy1a | joy2a);
wire [15:0] joy2 = (mod_club | mod_jmpst) ? joy2a : (joy1a | joy2a);
wire [15:0] joy1a;
wire [15:0] joy2a;

wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,mod_ponp,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joy1a),
	.joystick_1(joy2a)
);

reg mod_plus = 0;
reg mod_jmpst= 0;
reg mod_club = 0;
reg mod_orig = 0;
//reg mod_crush= 0;
reg mod_bird = 0;
reg mod_ms   = 0;
reg mod_gork = 0;
reg mod_mrtnt= 0;
reg mod_woodp= 0;
reg mod_eeek = 0;
reg mod_alib = 0;
reg mod_ponp = 0;
reg mod_van  = 0;
reg mod_pmm  = 0;
reg mod_dshop= 0;
reg mod_glob = 0;
reg mod_numcr= 0;

wire mod_gm = mod_gork | mod_mrtnt;

always @(posedge clk_sys) begin
	reg [7:0] mod = 0;
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;

	mod_orig <= (mod == 0);
	mod_plus <= (mod == 1);
	mod_club <= (mod == 2);
	//mod_crush<= (mod == 3);
	mod_bird <= (mod == 4);
	mod_ms   <= (mod == 5);
	mod_gork <= (mod == 6);
	mod_mrtnt<= (mod == 7);
	mod_woodp<= (mod == 8);
	mod_eeek <= (mod == 9);
	mod_alib <= (mod == 10);
	mod_ponp <= (mod == 11);
	mod_van  <= (mod == 12);
	mod_pmm  <= (mod == 13);
	mod_dshop<= (mod == 14);
	mod_glob <= (mod == 15);
	mod_jmpst<= (mod == 16);
	mod_numcr<= (mod == 17);
end

reg [7:0] sw[8];
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire m_up,m_down,m_left,m_right;
joyonedir jod
(
	clk_sys,
	mod_bird,
	{
		joy1[3],
		joy1[2],
		joy1[1],
		joy1[0]
	},
	{m_up,m_down,m_left,m_right}
);

wire m_up_2,m_down_2,m_left_2,m_right_2;
joyonedir jod_2
(
	clk_sys,
	mod_bird,
	{
		joy2[3],
		joy2[2],
		joy2[1],
		joy2[0]
	},
	{m_up_2,m_down_2,m_left_2,m_right_2}
);

wire m_fire     = joy1[4];
wire m_fire_2   = joy2[4];
wire m_start    = joy1[5] | joy2[5];
wire m_start_2  = joy1[6] | joy2[6];
wire m_coin     = joy1[7] | joy2[7];
wire m_cheat    = joy1[8] | joy2[8];
wire m_pause    = joy1[9] | joy2[9];

// PAUSE SYSTEM
wire				pause_cpu;
wire [7:0]		rgb_out;
pause #(3,3,2,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[24:23])
);

wire hblank, vblank;
wire ce_vid = ce_6m;
wire hs, vs;
wire [2:0] r,g;
wire [1:0] b;

arcade_video #(288,8) arcade_video
(
	.*,

	.clk_video(clk_vid),
	.ce_pix(ce_vid),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);

wire no_rotate = status[2] | direct_video | mod_ponp;
wire rotate_ccw = 0;
wire flip = 0;
wire video_rotated;
//screen_rotate screen_rotate (.*);

wire [9:0] audio;
assign AUDIO_L = {audio, 6'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = mod_van;

wire [7:0] in0xor = mod_ponp ? 8'hE0 : 8'hFF;
wire [7:0] in1xor = mod_ponp ? 8'h00 : 8'hFF;

wire reset;
assign reset = RESET | status[0] | buttons[1];

pacman pacman
(
	.O_VIDEO_R(r),
	.O_VIDEO_G(g),
	.O_VIDEO_B(b),
	.O_HSYNC(hs),
	.O_VSYNC(vs),
	.O_HBLANK(hblank),
	.O_VBLANK(vblank),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && !ioctl_index),

	.O_AUDIO(audio),

	.in0(sw[0] & (in0xor ^ {
		mod_eeek & m_fire_2,
		(mod_alib & m_fire) | ( mod_numcr ),
		~mod_numcr & m_coin,
		((mod_orig | mod_plus | mod_ms | mod_bird | mod_alib | mod_woodp | mod_numcr) & m_cheat) | ((mod_ponp | mod_van | mod_dshop) & m_fire),
		m_down,
		(~mod_numcr & m_right) | ( mod_numcr & m_left  ),
		(~mod_numcr & m_left ) | ( mod_numcr & m_right ),
		m_up
	})),

	.in1(sw[1] & (in1xor ^ {
		(mod_gm & m_fire_2) ,
		m_start_2 | (mod_eeek & m_fire) | (mod_jmpst & m_fire_2) | (mod_numcr & m_start),
		(~mod_numcr&m_start)   | (mod_jmpst & m_fire) | (mod_numcr & m_coin),
		(mod_gm & m_fire) | ((mod_alib | mod_ponp | mod_van | mod_dshop) & m_fire_2),
		~mod_pmm & m_down_2,
		mod_pmm ? m_fire : m_right_2,
		~mod_pmm & m_left_2,
		(~mod_pmm & m_up_2) | (mod_numcr&m_fire)
	})),
	
	.dipsw1(sw[2]),
	.dipsw2((mod_numcr| mod_ponp | mod_van | mod_dshop) ? sw[3] : 8'hFF),

	.mod_plus(mod_plus),
	.mod_jmpst(mod_jmpst),
	.mod_bird(mod_bird),
	.mod_ms(mod_ms),
	.mod_mrtnt(mod_mrtnt),
	.mod_woodp(mod_woodp),
	.mod_eeek(mod_eeek),
	.mod_alib(mod_alib),
	.mod_ponp(mod_ponp | mod_van | mod_dshop),
	.mod_van(mod_van | mod_dshop),
	.mod_dshop(mod_dshop),
	.mod_glob(mod_glob),
	.mod_club(mod_club),
	.flip_screen(status[7]),
	.h_offset(status[28:26]),
	.v_offset(status[31:29]),

	.RESET(reset),
	.CLK(clk_sys),
	.ENA_6(ce_6m),
	.ENA_4(ce_4m),
	.ENA_1M79(ce_1m79),

	.pause(pause_cpu),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write_enable(hs_write_enable),
	.hs_access_read(hs_access_read),
	.hs_access_write(hs_access_write)
);

// HISCORE SYSTEM
// --------------

wire [11:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_access_read;
wire hs_access_write;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(12),
	.CFG_ADDRESSWIDTH(3),
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[25]),
	.ram_address(hs_address),
	.data_from_ram(hs_data_out),
	.data_to_ram(hs_data_in),
	.data_from_hps(ioctl_dout),
	.data_to_hps(ioctl_din),
	.ram_write(hs_write_enable),
	.ram_intent_read(hs_access_read),
	.ram_intent_write(hs_access_write),
	.pause_cpu(hs_pause),
	.configured(hs_configured)
);


endmodule

module joyonedir
(
	input        clk,
	input        dis,
	input  [3:0] indir,
	output [3:0] outdir
);

reg  [3:0] mask = 0;
reg  [3:0] in1,in2;
wire [3:0] innew = in1 & ~in2;

assign outdir = in1 & mask;

always @(posedge clk) begin

	in1 <= indir;
	in2 <= in1;

	if(innew[0]) mask <= 1;
	if(innew[1]) mask <= 2;
	if(innew[2]) mask <= 4;
	if(innew[3]) mask <= 8;

	if(!(indir & mask) || dis) mask <= '1;
end

endmodule
