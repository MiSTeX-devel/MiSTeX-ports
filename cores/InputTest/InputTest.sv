/*============================================================================
	Input Test - emu module

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
	Date: 2021-12-22

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [47:0] HPS_BUS,

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

	input         OSD_STATUS,
	output   [7:0] DEBUG
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign FB_FORCE_BLANK = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.vh"
localparam CONF_STR = {
	"InputTest;;",
	"-;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"OGJ,Analog Video H-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"OKN,Analog Video V-Pos,0,-1,-2,-3,-4,-5,-6,-7,8,7,6,5,4,3,2,1;",
	"O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"-;",
	"O6,Rotate video,Off,On;",
	"O7,Flip video,Off,On;",
	"-;",
	"RA,Open menu;",
	"-;",
	"F0,BIN,Load BIOS;",
	"F3,BIN,Load Sprite ROM;",
	"F4,YM,Load Music (YM5/6);",
	"-;",
	"R0,Reset;",
	"J,A,B,X,Y,L,R,Select,Start;",
	"V,v",`BUILD_DATE
};

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;
wire [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;

wire [31:0] joystick_0;
wire [31:0] joystick_1;
wire [31:0] joystick_2;
wire [31:0] joystick_3;
wire [31:0] joystick_4;
wire [31:0] joystick_5;
wire [15:0] joystick_l_analog_0;
wire [15:0] joystick_l_analog_1;
wire [15:0] joystick_l_analog_2;
wire [15:0] joystick_l_analog_3;
wire [15:0] joystick_l_analog_4;
wire [15:0] joystick_l_analog_5;
wire [15:0] joystick_r_analog_0;
wire [15:0] joystick_r_analog_1;
wire [15:0] joystick_r_analog_2;
wire [15:0] joystick_r_analog_3;
wire [15:0] joystick_r_analog_4;
wire [15:0] joystick_r_analog_5;
wire  [7:0] paddle_0;
wire  [7:0] paddle_1;
wire  [7:0] paddle_2;
wire  [7:0] paddle_3;
wire  [7:0] paddle_4;
wire  [7:0] paddle_5;
wire  [8:0] spinner_0;
wire  [8:0] spinner_1;
wire  [8:0] spinner_2;
wire  [8:0] spinner_3;
wire  [8:0] spinner_4;
wire  [8:0] spinner_5;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;
wire [15:0] ps2_mouse_ext;
wire [32:0] timestamp;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	.joystick_4(joystick_4),
	.joystick_5(joystick_5),

	.joystick_l_analog_0(joystick_l_analog_0),
	.joystick_l_analog_1(joystick_l_analog_1),
	.joystick_l_analog_2(joystick_l_analog_2),
	.joystick_l_analog_3(joystick_l_analog_3),
	.joystick_l_analog_4(joystick_l_analog_4),
	.joystick_l_analog_5(joystick_l_analog_5),

	.joystick_r_analog_0(joystick_r_analog_0),
	.joystick_r_analog_1(joystick_r_analog_1),
	.joystick_r_analog_2(joystick_r_analog_2),
	.joystick_r_analog_3(joystick_r_analog_3),
	.joystick_r_analog_4(joystick_r_analog_4),
	.joystick_r_analog_5(joystick_r_analog_5),

	.paddle_0(paddle_0),
	.paddle_1(paddle_1),
	.paddle_2(paddle_2),
	.paddle_3(paddle_3),
	.paddle_4(paddle_4),
	.paddle_5(paddle_5),

	.spinner_0(spinner_0),
	.spinner_1(spinner_1),
	.spinner_2(spinner_2),
	.spinner_3(spinner_3),
	.spinner_4(spinner_4),
	.spinner_5(spinner_5),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	.ps2_mouse_ext(ps2_mouse_ext),

	.TIMESTAMP(timestamp)
);


////////////////////   CLOCKS   ///////////////////
wire clk_sys;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys)
);

///////////////////   CLOCK DIVIDER   ////////////////////
wire ce_pix;
wire ce_2;
jtframe_cen24 divider
(
	.clk(clk_sys),
	.cen6(ce_pix),
	.cen2(ce_2)
);

///////////////////   VIDEO   ////////////////////
wire hblank, vblank, hs, vs, hs_original, vs_original;
wire [7:0] r, g, b;

wire [23:0] rgb = {r,g,b};
wire rotate_ccw = status[7];
wire no_rotate = ~status[6];
wire flip = status[7];
screen_rotate screen_rotate (.*);
arcade_video #(320,24) arcade_video
(
	.*,
	.clk_video(clk_sys),
	.RGB_in(rgb),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	.fx(status[5:3])
);

// H/V offset
wire [3:0]  voffset = status[23:20];
wire [3:0]  hoffset = status[19:16];
jtframe_resync jtframe_resync
(
  .clk(clk_sys),
  .pxl_cen(ce_pix),
  .hs_in(hs_original),
  .vs_in(vs_original),
  .LVBL(~vblank),
  .LHBL(~hblank),
  .hoffset(hoffset),
  .voffset(voffset),
  .hs_out(hs),
  .vs_out(vs)
);

///////////////////   MAIN CORE   ////////////////////
wire rom_download = ioctl_download && (ioctl_index < 8'd2);
wire reset = (RESET | status[0] | rom_download);
assign LED_USER = rom_download;

system system(
	.clk_24(clk_sys),
	.ce_6(ce_pix),
	.ce_2(ce_2),
	.reset(reset),
	.pause(1'b0),
	.menu(status[10] || buttons[1]),
	.VGA_HS(hs_original),
	.VGA_VS(vs_original),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HB(hblank),
	.VGA_VB(vblank),
	.dn_addr(ioctl_addr[16:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),
	.dn_index(ioctl_index),
	.joystick({joystick_5,joystick_4,joystick_3,joystick_2,joystick_1,joystick_0}),
	.analog_l({joystick_l_analog_5,joystick_l_analog_4,joystick_l_analog_3,joystick_l_analog_2,joystick_l_analog_1,joystick_l_analog_0}),
	.analog_r({joystick_r_analog_5,joystick_r_analog_4,joystick_r_analog_3,joystick_r_analog_2,joystick_r_analog_1,joystick_r_analog_0}),
 	.paddle({paddle_5,paddle_4,paddle_3,paddle_2,paddle_1,paddle_0}),
	.spinner({7'b0,spinner_5,7'b0,spinner_4,7'b0,spinner_3,7'b0,spinner_2,7'b0,spinner_1,7'b0,spinner_0}),
	.ps2_key(ps2_key),
	.ps2_mouse({ps2_mouse_ext,7'b0,ps2_mouse}),
	.timestamp(timestamp),
	.AUDIO_L(AUDIO_L),
	.AUDIO_R(AUDIO_R)
);

endmodule
