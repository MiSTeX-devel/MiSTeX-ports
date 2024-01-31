//=========================================================
//  Arcade: SEGA SYSTEM 1  for MiSTer
//
//                        Copyright (c) 2019,20 MiSTer-X
//=========================================================

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
assign FB_FORCE_BLANK = '0;

wire screen_H = status[6]|~SYSMODE[1]|direct_video;
wire [1:0] ar = status[15:14];

assign VIDEO_ARX = (!ar) ? (screen_H ? 12'd2400 : 12'd2191) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (screen_H ? 12'd2191 : 12'd2400) : 12'd0;

`include "build_id.vh" 
localparam CONF_STR = {
	"A.SEGASYS1;;",
	"-;",
	"H0OEF,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O6,Orientation,Vert,Horz;", 
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O7,Pause when OSD is open,On,Off;",
	"-;",
	"DIP;",
	"-;",
	"OOS,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
	"OTV,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"-;",
	"R0,Reset;",
	"J1,Trig1,Trig2,Trig3,Trig4,Trig5,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,B,X,,,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

wire [4:0] HOFFS = status[28:24];
wire [2:0] VOFFS = status[31:29];


////////////////////   CLOCKS   ///////////////////

wire clk_48M;
wire clk_hdmi = clk_48M;
wire clk_sys  = clk_48M;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_48M)
);

///////////////////////////////////////////////////

wire	[31:0]	status;
wire	[1:0]		buttons;
wire				forced_scandoubler;
wire				direct_video;

wire				ioctl_download;
wire				ioctl_upload;
wire				ioctl_wr;
wire	[7:0]		ioctl_index;
wire	[24:0]	ioctl_addr;
wire	[7:0]		ioctl_dout;
wire	[7:0]		ioctl_din;

wire	[15:0]	joy1, joy2;
wire	[15:0]	joy = joy1 | joy2;
wire	[8:0]		spinner_0, spinner_1;
wire	[24:0]	ps2_mouse;

wire	[21:0]	gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),

	.status(status),
	.status_menumask(direct_video),
	.video_rotated(video_rotated),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.ps2_mouse(ps2_mouse),
	.joystick_0(joy1),
	.joystick_1(joy2),
	.spinner_0(spinner_0),
	.spinner_1(spinner_1)
);

reg [7:0] SYSMODE;	// [0]=SYS1/SYS2,[1]=H/V,[2]=H256/H240,[3]=water match control,[4]=CW/CCW,[5]=spinner,[6] HS start delay for TeddyBoy Blues (27 seconds!)
reg [7:0] DSW[8];
always @(posedge clk_sys) begin
	if (ioctl_wr) begin
		if ((ioctl_index==1  ) && (ioctl_addr==0))   SYSMODE <= ioctl_dout;
		if ((ioctl_index==254) && !ioctl_addr[24:3]) DSW[ioctl_addr[2:0]] <= ioctl_dout;
	end
end

wire m_lup    = joy1[3];
wire m_ldown  = joy1[2];
wire m_lleft  = joy1[1];
wire m_lright = joy1[0];
wire m_rup    = joy1[7] | joy2[3];
wire m_rdown  = joy1[6] | joy2[2];
wire m_rleft  = joy1[5] | joy2[1];
wire m_rright = joy1[4] | joy2[0];
wire m_trig   = joy1[8];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_trig_1 = joy[4];
wire m_trig_2 = joy[5];
wire m_trig_3 = joy[6];

wire m_start1 = joy[9];
wire m_start2 = joy[10];
wire m_coin   = joy[11];
wire m_pause  = joy[12];

// PAUSE SYSTEM
reg				pause;									// Pause signal (active-high)
reg				pause_toggle = 1'b0;					// User paused (active-high)
reg [31:0]		pause_timer;							// Time since pause
reg [31:0]		pause_timer_dim = 31'h1C9C3800;	        // Time until screen dim (10 seconds @ 48Mhz)
reg 			dim_video;						        // Dim video output (active-high)

// Pause when highscore module requires access, user has pressed pause, or OSD is open and option is set
assign pause = hs_access | pause_toggle  | (OSD_STATUS && ~status[7]);
assign dim_video = (pause_timer >= pause_timer_dim) ? 1'b1 : 1'b0;

always @(posedge clk_hdmi) begin
	reg old_pause;
	old_pause <= m_pause;
	if(~old_pause & m_pause) pause_toggle <= ~pause_toggle;
	if(pause_toggle)
	begin
		if(pause_timer<pause_timer_dim)
		begin
			pause_timer <= pause_timer + 1'b1;
		end
	end
	else
	begin
		pause_timer <= 1'b0;
	end
end

///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire [2:0] r,g;
wire [1:0] b;
wire [7:0] rgb_out = dim_video ? {r >> 1,g >> 1, b >> 1} : {r,g,b};

reg ce_pix;
always @(posedge clk_hdmi) begin
	reg old_clk;
	old_clk <= ce_vid;
	ce_pix  <= old_clk & ~ce_vid;
end

arcade_video #(288,8) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(status[5:3])
);


wire no_rotate = screen_H;
wire rotate_ccw = ~SYSMODE[4];
wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);

wire			PCLK_EN;
wire  [8:0] HPOS,VPOS;
wire  [7:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),
	.VPOS(VPOS),
	.CLK(clk_sys),
	.PCLK_EN(PCLK_EN),
	.iRGB(POUT),
	.oRGB({b,g,r}),
	.HBLK(hblank),
	.VBLK(vblank),
	.HSYN(hs),
	.VSYN(vs),
	.H240(SYSMODE[2]),
	.HOFFS(HOFFS),
	.VOFFS(VOFFS)
);

assign ce_vid = PCLK_EN;

wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0; // unsigned PCM


///////////////////////////////////////////////////

wire iRST = RESET | status[0] | buttons[1];

reg [7:0] INP0, INP1, INP2;
always @(posedge clk_sys) begin
	if (SYSMODE[5]) begin
		INP0 = ~spin;
		INP1 = ~spin;
		INP2 = ~{m_trig_1 || ps2_mouse[2:0], m_trig_1 || ps2_mouse[2:0], m_start2, m_start1, 3'b000, m_coin};
	end
	else if (SYSMODE[3]) begin
		INP0 = ~{m_lleft, m_lright, m_lup, m_ldown, m_rleft, m_rright, m_rup, m_rdown};
		INP1 = ~{m_lleft, m_lright, m_lup, m_ldown, m_rleft, m_rright, m_rup, m_rdown};
		INP2 = ~{m_trig, m_trig, m_start2, m_start1, 3'b000, m_coin};
	end
	else begin
		INP0 = ~{m_left, m_right, m_up, m_down,1'd0, m_trig_2, m_trig_1, m_trig_3};
		INP1 = ~{m_left, m_right, m_up, m_down,1'd0, m_trig_2, m_trig_1, m_trig_3};
		INP2 = ~{2'b00, m_start2, m_start1, 3'b000, m_coin}; 
	end
end

wire [7:0] spin;
spinner #(15,25,5) spinner
(
	.clk(clk_sys),
	.reset(iRST),
	.minus(m_left),
	.plus(m_right),
	.fast(m_trig_2),
	.strobe(vs),
	.spin1_in(use_mouse ? {ps2_mouse[24],ps2_mouse[15:8]} : spinner_0),
	.spin2_in(spinner_1),
	.spin_out(spin)
);

reg use_mouse = 0;
always @(posedge clk_sys) begin
	reg old_ms;
	reg old_sp;
	
	old_ms <= ps2_mouse[24];
	if(old_ms ^ ps2_mouse[24]) use_mouse = 1;
	
	old_sp <= spinner_0[8];
	if(old_sp ^ spinner_0[8]) use_mouse = 0;
end

SEGASYSTEM1 GameCore
( 
	.clk48M(clk_sys),
	.reset(iRST),

	.INP0(INP0),
	.INP1(INP1),
	.INP2(INP2),
	.DSW0(DSW[0]),
	.DSW1(DSW[1]),

	.PH(HPOS),
	.PV(VPOS),
	.PCLK_EN(PCLK_EN),
	.POUT(POUT),
	.SOUT(AOUT),

	.ROMCL(clk_sys),
	.ROMAD(ioctl_addr),
	.ROMDT(ioctl_dout),
	.ROMEN(ioctl_wr & ioctl_index==0),
	
	.PAUSE_N(~pause),
	.HSAD(hs_address),
	.HSDO(ioctl_din),
	.HSDI(hs_data_in),
	.HSWE(hs_write)

);


wire [15:0]hs_address;
wire [7:0]hs_data_in;
wire hs_write;
wire hs_access;

hiscore #(
	.HS_ADDRESSWIDTH(16),
	.HS_SCOREWIDTH(9),
	.CFG_ADDRESSWIDTH(5),
	.CFG_LENGTHWIDTH(2)
) hi (
	.clk(clk_sys),
	.reset(iRST),
	.ioctl_upload(ioctl_upload),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ram_address(hs_address),
	.data_to_ram(hs_data_in),
	.ram_write(hs_write),
	.ram_access(hs_access)
);


endmodule
