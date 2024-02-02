//============================================================================
//  Arcade: Donkey Kong
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
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
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

assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE = 0;
assign FB_FORCE_BLANK = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2]|mod_pestplace)  ? 8'd8 : 8'd7) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2]|mod_pestplace)  ? 8'd7 : 8'd8) : 12'd0;

// Status Bit Map:
//             Upper                             Lower
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXX X           XXXXXXXXXXXXX

`include "build_id.vh"
localparam CONF_STR = {
	"A.DKONG;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H1H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"H1O7,Flip Screen,Off,On;",
	"OOS,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
	"OTV,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"O6,Sound Effects,Sampled,Emulated;",
	"H2ON,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OL,Pause when OSD is open,On,Off;",
	"P1OM,Dim video after 10s,On,Off;",
	"-;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Jump,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys,clk_49;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_49),
	.outclk_1(clk_sys),
	.locked(pll_locked)
);

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

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,mod_pestplace,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);


// DIP switches
reg [7:0] sw[8];
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

// Core specific mods
//reg mod_dk = 0;
reg mod_dkjr = 0;
reg mod_dk3 = 0;
reg mod_radarscope=0;
reg mod_pestplace=0;


always @(posedge clk_sys) begin
	reg [7:0] mod = 0;
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;

	//mod_dk <= (mod == 0);
	mod_dkjr <= (mod == 1);
	mod_dk3 <= (mod == 2);
	mod_radarscope <= (mod == 3);
	mod_pestplace   <= (mod == 4);
end

// Player inputs
wire m_up_2    = mod_pestplace ? joystick_1[3] : joy[3];
wire m_down_2  = mod_pestplace ? joystick_1[2] : joy[2];
wire m_left_2  = mod_pestplace ? joystick_1[1] : joy[1];
wire m_right_2 = mod_pestplace ? joystick_1[0] : joy[0];
wire m_fire_2  = mod_pestplace ? joystick_1[4] : joy[4];

wire m_up      = mod_pestplace ? joystick_0[3] : joy[3];
wire m_down    = mod_pestplace ? joystick_0[2] : joy[2];
wire m_left    = mod_pestplace ? joystick_0[1] : joy[1];
wire m_right   = mod_pestplace ? joystick_0[0] : joy[0];
wire m_fire    = mod_pestplace ? joystick_0[4] : joy[4];

wire m_start1 =  joy[5];
wire m_start2 =  joy[6];
wire m_coin   =  joy[7];
wire m_pause  =  joy[8];

// PAUSE SYSTEM
wire pause_cpu;

wire [11:0] rgb_out;

pause #(4,4,4,25) pause (
  .*,
  .reset(reset),
  .user_button(m_pause),
  .pause_request(),
  .options(~status[22:21])
);

wire hblank, vblank;
wire hs_n, vs_n;
wire [3:0] r,g,b;

reg ce_pix;
always @(posedge clk_49) begin
	reg [2:0] div;

	div <= div + 1'd1;
	ce_pix <= !div;
end

wire no_rotate = status[2] | direct_video | mod_pestplace;
wire rotate_ccw = 0;
wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);


arcade_video #(256,12) arcade_video
(
	.*,

	.clk_video(clk_49),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs_n),
	.VSync(~vs_n),

	.fx(status[5:3])
);


wire [15:0] audio;
assign AUDIO_L = audio;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;

assign hblank = hbl[8];

//reg  ce_vid;
wire clk_pix;
wire hbl0;
reg [8:0] hbl;
always @(posedge clk_sys) begin
	reg old_pix;
	old_pix <= clk_pix;
	//ce_vid <= 0;
	if(~old_pix & clk_pix) begin
		//ce_vid <= 1;
		hbl <= (hbl<<1)|hbl0;
	end
end

wire reset = RESET | status[0] | buttons[1]| ioctl_download;


wire [15:0] main_rom_a;
wire [7:0] main_rom_do;
wire [11:0] sub_rom_a;
wire [7:0] sub_rom_do;
wire [18:0] wav_rom_a;
wire [7:0] wav_rom_do;


dpram #(15,8) cpu_rom (
	.clock_a(clk_sys),
	.address_a(main_rom_a[14:0]),
	.q_a(main_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[14:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr < 'd32768) && !ioctl_index),
	.data_b(ioctl_dout)
	);
dpram #(12,8) snd_rom (
	.clock_a(clk_sys),
	.address_a(sub_rom_a[11:0]),
	.q_a(sub_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[11:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr < 'hF000 && ioctl_addr >= 'hE000) && !ioctl_index),
	.data_b(ioctl_dout)
	);
dpram #(16,8) wav_rom (
	.clock_a(clk_sys),
	.address_a(wav_rom_a[15:0]),
	.q_a(wav_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[15:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr >= 'hFF00) && !ioctl_index),
	.data_b(ioctl_dout)
	);





dkong_top dkong(
	.I_CLK_24576M(clk_sys),
	.I_RESETn(~reset),
	.I_U1(~m_up),
	.I_D1(~m_down),
	.I_L1(~m_left),
	.I_R1(~m_right),
	.I_J1(~m_fire),

	.I_U2(~m_up_2),
	.I_D2(~m_down_2),
	.I_L2(~m_left_2),
	.I_R2(~m_right_2),
	.I_J2(~m_fire_2),

	.I_S1(~m_start1),
	.I_S2(~m_start2),
	.I_C1(~m_coin),

	.I_DIP_SW(sw[0]),

	.I_DKJR(mod_dkjr|mod_pestplace|mod_dk3),
	.I_DK3B(mod_dk3),
	.I_RADARSCP(mod_radarscope),
	.I_PESTPLCE(mod_pestplace),

	.O_PIX(clk_pix),

	.flip_screen(status[7]),
	.use_emulated_sfx(status[6]),
	.H_OFFSET(status[28:24]),
	.V_OFFSET(status[31:29]),

	.O_SOUND_DAT(audio),
	.O_VGA_R(r),
	.O_VGA_G(g),
	.O_VGA_B(b),
	.O_H_BLANK(hbl0),
	.O_V_BLANK(vblank),
	.O_VGA_H_SYNCn(hs_n),
	.O_VGA_V_SYNCn(vs_n),

	.DL_ADDR(ioctl_addr[15:0]),
	.DL_WR(ioctl_wr && ioctl_addr[23:16] == 0 && !ioctl_index),
	.DL_DATA(ioctl_dout),
	.MAIN_CPU_A(main_rom_a),
	.MAIN_CPU_DO(main_rom_do),
	.SND_ROM_A(sub_rom_a),
	.SND_ROM_DO( sub_rom_do),
	.WAV_ROM_A(wav_rom_a),
	.WAV_ROM_DO( wav_rom_do),

	.paused(pause_cpu),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(hs_data_out),
	.hs_write(hs_write_enable),
	.hs_access(hs_access_read|hs_access_write)
	);


// HISCORE SYSTEM
// --------------
wire [15:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_access_read;
wire hs_access_write;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(16),
	.HS_SCOREWIDTH(8),			// 241 bytes
	.CFG_ADDRESSWIDTH(4),		// 8 entries
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[23]),
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
