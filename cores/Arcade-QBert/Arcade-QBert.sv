//============================================================================
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
//
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

	input         OSD_STATUS,

	output     [3:0]  DEBUG
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_USER  = ioctl_download;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? ((no_rotate) ? 8'd8 : 8'd7) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((no_rotate) ? 8'd7 : 8'd8) : 12'd0;

`include "build_id.vh"
localparam CONF_STR = {
  "QBert;;",
  "-;",
  //"F0,bin,Rom Load;",
  "H0O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
  "O5,Orientation,Vert,Horz;",
  "OFH,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
  "OB,VFlip,Off,On;",
//  "OC,HFlip,Off,On;",
  "-;",
  "O6,Test mode,Off,On;",
  "O7,Original column bug,Off,On;",
  "OA,Diagonal joystick,Off,On;",
  "-;",
  "DIP;",
  "-;",
  "R0,Reset and close OSD;",
  "J1,Service Select,Start 1P,Start 2P,Coin;",
	"jn,A,Start,Select,R;",
	"jp,B,Start,,Select;",
  "V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire direct_video;
wire [21:0] gamma_bus;
wire  [1:0] buttons;
wire [31:0] status;
wire [10:0] ps2_key;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire [15:0] joystick_analog_0;

wire [8:0] spinner_0;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
  .clk_sys(clk_25),
  .HPS_BUS(HPS_BUS),
  .EXT_BUS(),

  .gamma_bus(gamma_bus),
  .direct_video(direct_video),
	.video_rotated(video_rotated),

  .forced_scandoubler(forced_scandoubler),

  .buttons(buttons),
  .status(status),
  .status_menumask({direct_video}),

  .ps2_key(ps2_key),

  .ioctl_download(ioctl_download),
  .ioctl_wr(ioctl_wr),
  .ioctl_addr(ioctl_addr),
  .ioctl_dout(ioctl_dout),
  .ioctl_wait(ioctl_wait),
  .ioctl_index(ioctl_index),

  .joystick_0(joystick_0),
  .joystick_1(joystick_1),
  
  .joystick_l_analog_0(joystick_analog_0),
  .spinner_0(spinner_0),
   .DEBUG(DEBUG)
);

///////////////////////   CLOCKS   ///////////////////////////////

// ** Video
// XTAL = 20M
// CLK = 10M
// HCLK = 5M
// ** CPU
// XTAL = 15M
// CPU_CLK from 8284 = 5M

wire clk_sys, clk_40, clk_25, core_clk;
pll pll
(
  .refclk(CLK_50M),
  .rst(0),
  .outclk_0(clk_sys), // 50Mhz mostly used for bram & sound
  .outclk_1(clk_40),   // rotation 40MHz + video 10MHz & 5MHz
  .outclk_2(clk_25),
  .outclk_3(core_clk)
);

reg [3:0] cnt1;
reg cpu_clk; // clock enable
always @(posedge clk_sys) begin
  cnt1 <= cnt1 + 5'd1;
  if (cnt1 == 5'd9) begin
    cnt1 <= 5'd0;
    cpu_clk <= 1'b1;
  end
  else cpu_clk <= 1'b0;
end

// derive sound clock from clk_sys
reg [5:0] cnt2;
reg sound_clk;
always @(posedge clk_sys) begin
  cnt2 <= cnt2 + 6'd1;
  sound_clk <= 1'b0;
  if (cnt2 == 6'd55) begin
    cnt2 <= 6'd0;
    sound_clk <= 1'b1;
  end
end

reg [1:0] cnt3;
always @(posedge clk_40)
  cnt3 <= cnt3 + 2'd1;

wire clk_10 = cnt3[1];

reg clk_5;
always @(posedge clk_10)
  clk_5 <= ~clk_5;


wire reset = RESET | status[0] | buttons[1];

//////////////////////////////////////////////////////////////////

// read dip switches

reg [7:0] sw[8];
always @(posedge clk_25) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire HBlank, VBlank;
wire HSync, VSync;

wire [5:0] OP2720;

localparam mod_qbert  		= 0;
localparam mod_qub    		= 1;
localparam mod_mplanets    = 2;
localparam mod_krull    = 3;
localparam mod_curvebal = 4;
localparam mod_tylz = 5;
localparam mod_insector = 6;

reg [7:0] mod = 255;
always @(posedge clk_25) if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;


reg [7:0] IP1710;
reg [7:0] IP4740;
reg [7:0] IPA1J2;


always @(*) begin

  IPA1J2 <= 8'd0;

  IP1710 <= {
    joystick_0[4], // test 1
    ~status[6],    // test 2
    2'b0,
    joystick_0[7], // coin 1
    1'b0,//joystick_0[6], // coin 2
    joystick_0[6], // p2
    joystick_0[5]  // p1
  };

  if (~status[10]) begin
    IP4740 <= {
      4'b0,
      joystick_0[2], // left
      joystick_0[3], // right
      joystick_0[1], // up
      joystick_0[0]  // down
    };
  end

  case (mod)
    mod_qbert:
    begin
      if (status[10]) begin
        IP4740 <= {
          4'b0,
          joystick_0[2] & joystick_0[1], // left + up
          joystick_0[3] & joystick_0[0], // right + down
          joystick_0[1] & joystick_0[3], // up + right
          joystick_0[0] & joystick_0[2] // down + left
        };
      end
    end

    mod_qub:
    begin
    end

    mod_mplanets:
    begin
      IP1710 <= {
          ~status[6],    // test 2
          joystick_0[9], // test 1
          2'b0,
          1'b0,
          1'b0, // coin 1
          1'b0, // coin 2
          joystick_0[7]  // coin
      };

      IP4740 <= {
        joystick_0[8],// button 2

        joystick_0[6], // p2
        joystick_0[5],  // p1

        joystick_0[4], // button 1
        joystick_0[1], // up
        joystick_0[2], // right
        joystick_0[0],  // down
        joystick_0[3] // left
      };
      
      IPA1J2 <= spinner_0[7:0];
      
    end

    mod_krull:
    begin
    end

    mod_curvebal:
    begin
      IP1710 <= {
        2'b0,
        1'b0, // p2
        1'b0,//joystick_0[6],
        1'b0,// coin 2
        joystick_0[7], // coin 1
        joystick_0[8], // test 1
        ~status[6]     // test 2
      };

      IP4740 <= {
        1'b0, // n/a
        joystick_0[9], // bunt
        1'b0, // n/a
        joystick_0[11], // pitch right
        1'b0, // n/a
        joystick_0[10], // pitch left
        joystick_0[4], // swing
        1'b0
      };
    end

    mod_tylz:
    begin
      IP1710 <= { // IN1
        4'b0,
        joystick_0[7], // coin 1
        1'b0,//joystick_0[6], // coin 2
        joystick_0[4], // test 1
        ~status[6]

      };

      IP4740 <= { // IN4
        1'b0,
        joystick_0[6], // p2
        joystick_0[5],  // p1

        joystick_0[8], // button 1
        joystick_0[3], // right
        joystick_0[0], // down
        joystick_0[2], // left
        joystick_0[1]  // up
      };
    end
    mod_insector:
    begin
      IP1710 <= { // IN1
        1'b0,
        ~status[6],
        joystick_1[9],
        joystick_1[8],
        1'b0,//joystick_0[6], // coin 2
        joystick_0[7], // coin 1
        joystick_0[9],
        joystick_0[8]

      };

      IP4740 <= { // IN4

        joystick_1[1],
        joystick_1[2],
        joystick_1[0],
        joystick_1[3],


        joystick_0[1],
        joystick_0[2],
        joystick_0[0],
        joystick_0[3]
      };
    end
    default:
    begin
    end
  endcase
end

wire [7:0] audio;
wire [7:0] red, green, blue;

assign AUDIO_L = { audio, 8'd0 };
assign AUDIO_R = { audio, 8'd0 };

wire rom_init = ioctl_download && (ioctl_index==0);

mylstar_board mylstar_board
(
  .clk_sys(clk_sys),
  .reset(reset),

  .CLK(clk_10),
  .CLK5(clk_5),

  .CPU_CORE_CLK(core_clk),
  .CPU_CLK(cpu_clk),

  .red(red),
  .green(green),
  .blue(blue),

  .IP1710(IP1710),
  .IP4740(IP4740),
  .IPA1J2(IPA1J2),
  .OP2720(OP2720),
  .OP3337(),

  .dip_switch(sw[0]),

  .rom_init(rom_init),
  .rom_init_address(ioctl_addr),
  .rom_init_data(ioctl_dout),
  .rom_index(ioctl_index),
  
  .vflip(status[11]),
  .hflip(1'b0)
);

// audio board
ma216_board ma216_board(
  .clk(sound_clk),
  .clk_sys(clk_sys),
  .reset(reset),
  .IP2720(OP2720),
  .audio(audio),
  .rom_init(rom_init),
  .rom_init_address(ioctl_addr),
  .rom_init_data(ioctl_dout)
);

// 256x240 15KHz 60Hz


// copying fx into a register
// fixes a timing problem
reg [2:0]fx;
always @(posedge clk_25)
begin
  fx <= status[17:15];
end



wire rotate_ccw = ~status[11];
wire no_rotate = status[5] | (mod==mod_tylz) | (mod==mod_insector) | direct_video;
//wire scandoubler = (status[17:15] || forced_scandoubler);
wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);

arcade_video #(256,24,0) arcade_video
(
  .*,
  .clk_video(clk_40),
  .RGB_in({ rgbout[23:16], rgbout[15:8], rgbout[7:0] })
);

wire [23:0] rgbout;
HVGEN hvgen(
  .vclk(clk_5),
  .rgbin({ red, green, blue }),
  .rgbout(rgbout),
  .hb(HBlank),
  .vb(VBlank),
  .hs(HSync),
  .vs(VSync),
  .colfix(~status[7])
);

wire ce_pix = clk_5;

endmodule

module HVGEN (
  input vclk,
  input [23:0] rgbin,
  output [23:0] rgbout,
  input colfix,
  output reg hb = 1,
  output reg vb = 1,
  output reg hs = 1,
  output reg vs = 1
);

wire [7:0] endhb = colfix ? 5 : 0;
reg [8:0] hcnt;
reg [7:0] vcnt;
assign rgbout = hb | vb ? 24'd0 : rgbin;
always @(posedge vclk) begin
  hcnt <= hcnt + 1'b1;
  case (hcnt)
    0: hb <= colfix ? 1'b1 : 1'b0; // keep hbl active if colfix
    5: hb <= 1'b0;
    255: hb <= 1'b1;
    283: hs <= 1'b0;
    303: hs <= 1'b1;
    317: begin
      vcnt <= vcnt + 1'b1;
      hcnt <= 1'b0;
      case (vcnt)
        239: vb <= 1'b1;
        251: vs <= 1'b0;
        254: vs <= 1'b1;
        255: begin vcnt <= 1'b0; vb <= 1'b0; end
      endcase
    end
  endcase
end

endmodule
