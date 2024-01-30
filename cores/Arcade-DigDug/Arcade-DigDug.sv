//============================================================================
//  Arcade: DigDug
//
//  Original implimentation and port to MiSTer by MiSTer-X 2019
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

assign VGA_F1     = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE= 0;
assign USER_OUT   = '1;
assign LED_USER   = ioctl_download;
assign LED_DISK   = 0;
assign LED_POWER  = 0;
assign BUTTONS    = 0;
assign AUDIO_MIX  = 0;
assign HDMI_FREEZE= 0;
assign FB_FORCE_BLANK = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2] ) ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] ) ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.vh" 
localparam CONF_STR = {
	"A.DIGDUG;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O89,Difficulty,Medium,Hardest,Easy,Hard;",
	"OAB,Life,3,5,1,2;",
	"OCE,Bonus Life,M3,M4,M5,M6,M7,Nothing,M1,M2;",
	"OF,Allow Continue,No,Yes;",
	"OG,Demo Sound,Off,On;",
	//"OI,Cabinet,Upright,Cocktail;",
	"-;",
	"OH,Service Mode,Off,On;",
	
	"OI,Vertical flip,Off,On;",
	
	"H1OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Pump,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};


////////////////////   CLOCKS   ///////////////////

wire clk_hdmi;
wire clk_48M;
wire clk_sys = clk_hdmi;

pll pll
(
	.rst(1'b0),
	.refclk(CLK_50M),
	.outclk_0(clk_48M),
	.outclk_1(clk_hdmi)  // 24.573863 MHz
);

///////////////////////////////////////////////////

wire	[31:0]	status;
wire	[1:0]		buttons;
wire				forced_scandoubler;
wire	[21:0]	gamma_bus;
wire				direct_video;

wire				ioctl_download;
wire				ioctl_upload;
wire				ioctl_upload_req;
wire				ioctl_wr;
wire	[7:0]		ioctl_index;
wire	[24:0]	ioctl_addr;
wire	[7:0]		ioctl_dout;
wire	[7:0]		ioctl_din;

wire	[10:0]	ps2_key;
wire	[15:0]	joystk1, joystk2;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.status_menumask({~hs_configured,direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystk1),
	.joystick_1(joystk2)
);



//wire bCabinet  = status[18];//1'b0;	// (upright only)
wire bCabinet  = 1'b0;	// (upright only)

wire m_up2     = joystk2[3];
wire m_down2   = joystk2[2];
wire m_left2   = joystk2[1];
wire m_right2  = joystk2[0];
wire m_trig2   = joystk2[4];

wire m_start1  = joystk1[5] | joystk2[5] ;
wire m_start2  = joystk1[6] | joystk2[6] ;

wire m_up1     = joystk1[3] | (bCabinet ? 1'b0 : m_up2);
wire m_down1   = joystk1[2] | (bCabinet ? 1'b0 : m_down2);
wire m_left1   = joystk1[1] | (bCabinet ? 1'b0 : m_left2);
wire m_right1  = joystk1[0] | (bCabinet ? 1'b0 : m_right2);
wire m_trig1   = joystk1[4] | (bCabinet ? 1'b0 : m_trig2);

wire m_coin1   = joystk1[7];
wire m_coin2   = joystk2[7];
wire m_pause1  = joystk1[8];
wire m_pause2  = joystk2[8];
wire m_pause   = m_pause1 | m_pause2;

// PAUSE SYSTEM
wire				pause_cpu;
wire [11:0]		rgb_out;
pause #(4,4,4,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire [3:0] r,g,b;

reg ce_pix;
always @(posedge clk_hdmi) begin
	reg old_clk;
	old_clk <= ce_vid;
	ce_pix  <= old_clk & ~ce_vid;
end

wire no_rotate=status[2]|direct_video;
wire rotate_ccw=1'b0;
screen_rotate screen_rotate 
(
	.*,
	.flip(),
	.video_rotated()
);


arcade_video #(288,12) arcade_video
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

wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.iRGB(POUT),
	.oRGB({b,g,r}),.HBLK(hblank),.VBLK(vblank),.HSYN(hs),.VSYN(vs)
);
assign ce_vid = PCLK;


wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0; // unsigned PCM


///////////////////////////////////////////////////

wire rom_download = ioctl_download & !ioctl_index;
wire	reset = RESET | status[0] | buttons[1] | ioctl_download;

wire  [1:0] COIA = 2'b00;			// 1coin/1credit
wire  [2:0] COIB = 3'b001;			// 1coin/1credit
wire			CABI = ~bCabinet;
wire  		FRZE = 1'b1;

wire	[1:0] DIFC = status[9:8]+2'h2;
wire  [1:0] LIFE = status[11:10]+2'h2;
wire  [2:0] EXMD = status[14:12]+3'h3;
wire			CONT = ~status[15];
wire			DSND = ~status[16];
wire     SERVICE = status[17];
wire      V_FLIP = status[18];

wire  [7:0] DSW0 = {LIFE,EXMD,COIB};
wire  [7:0] DSW1 = {COIA,FRZE,DSND,CONT,CABI,DIFC};
wire  [7:0] INP0 = {SERVICE, 1'b0, m_coin2, m_coin1, m_start2, m_start1, m_trig2, m_trig1 };
wire  [7:0] INP1 = {m_left2, m_down2, m_right2, m_up2, m_left1, m_down1, m_right1, m_up1 };

wire  [7:0] oPIX;
wire  [7:0] oSND;

FPGA_DIGDUG GameCore ( 
	.RESET(reset),.MCLK(clk_48M),
	.INP0(INP0),.INP1(INP1),.DSW0(DSW0),.DSW1(DSW1),
	.PH(HPOS),.PV(VPOS),.PCLK(PCLK),.POUT(oPIX),
	.SOUT(oSND),
	
	.ROMCL(clk_sys),.ROMAD(ioctl_addr[15:0]),.ROMDT(ioctl_dout),.ROMEN(ioctl_wr & rom_download),

	.V_FLIP(V_FLIP),
	
	.PAUSE(pause_cpu),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(hs_data_out),
	.hs_write(hs_write_enable),
	.hs_access(hs_access_read | hs_access_write)
);

assign POUT = {oPIX[7:6],2'b00,oPIX[5:3],1'b0,oPIX[2:0],1'b0};
assign AOUT = {oSND,8'h0};


// HISCORE SYSTEM
// --------------
wire [10:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_access_read;
wire hs_access_write;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(11),
	.HS_SCOREWIDTH(6),
	.CFG_ADDRESSWIDTH(1),
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
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
