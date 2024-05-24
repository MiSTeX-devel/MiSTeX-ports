// ====================================================================
//
//  Amstrad CPC Gate Array
//  Based on 40010-simplified_V03.pdf by Gerald
//
//  Copyright (C) 2020 Gyorgy Szombathelyi <gyurco@freemail.hu>
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


// synchronous sync+int generator
module syncgen_sync (
	input  clk,
	input  CCLK_EN_N,
	input  RESET_N,
	input  MREQ_N,
	input  M1_N,
	input  IORQ_N,
	input  HSYNC_I,
	input  VSYNC_I,
	input  irq_reset,

	output HSYNC_O,
	output VSYNC_O,
	output SYNC_N,
	output reg INT_N,
	output HCNTLT28,
	output reg mode_sync_en
);

///// SYNC AND IRQ GEN /////

reg  [5:0] intcnt;
reg  [5:0] intcnt_reg;
reg  [5:0] intcnt_next;
reg  [4:0] hcnt;
reg  [4:0] hcnt_reg;
reg  [4:0] hcnt_next;
reg  [3:0] hdelay;
reg  [3:0] hdelay_reg;

reg        vsync_d; // u803
wire       hsync_n = ~HSYNC_I; // u801
reg        hsync_n_d;
reg        vsync_o_d; // u812
wire       irqack_rst;

// edge detectors
always @(posedge clk) begin
	hsync_n_d <= hsync_n;
	if (CCLK_EN_N) begin
		vsync_d <= VSYNC_I;
		vsync_o_d <= VSYNC_O;
	end
end

wire hcnt_cnt = ~hsync_n_d & hsync_n;

// hsync counter
// vsync set if 4<=hcnt<8
assign VSYNC_O = hcnt[2] & ~hcnt[3] & ~hcnt[4]; // u806

assign HCNTLT28 = ~(hcnt[2] & hcnt[3] & hcnt[4]); // u802
wire hcnt_res0 = ~RESET_N | (hcnt_cnt & hcnt_next[2] & hcnt_next[3] & hcnt_next[4]); // u805
wire hcnt_res1 = VSYNC_I & ~vsync_d; // u810

always @(*) begin
	hcnt = hcnt_reg;
	if (hcnt_cnt) hcnt = hcnt_next;
	if (hcnt_res0) hcnt[0] = 0;
	if (hcnt_res1) hcnt[4:1] = 0;
end

always @(posedge clk) begin
	hcnt_reg <= hcnt;
	case (hcnt)
	5'h00: hcnt_next <= 5'h01;
	5'h01: hcnt_next <= 5'h06;
	5'h06: hcnt_next <= 5'h07;
	5'h07: hcnt_next <= 5'h04;
	5'h04: hcnt_next <= 5'h05;
	5'h05: hcnt_next <= 5'h0A;
	5'h0A: hcnt_next <= 5'h0B;
	5'h0B: hcnt_next <= 5'h08;
	5'h08: hcnt_next <= 5'h09;
	5'h09: hcnt_next <= 5'h0E;
	5'h0E: hcnt_next <= 5'h0F;
	5'h0F: hcnt_next <= 5'h0C;
	5'h0C: hcnt_next <= 5'h0D;
	5'h0D: hcnt_next <= 5'h12;
	5'h12: hcnt_next <= 5'h13;
	5'h13: hcnt_next <= 5'h10;
	5'h10: hcnt_next <= 5'h11;
	5'h11: hcnt_next <= 5'h16;
	5'h16: hcnt_next <= 5'h17;
	5'h17: hcnt_next <= 5'h14;
	5'h14: hcnt_next <= 5'h15;
	5'h15: hcnt_next <= 5'h1A;
	5'h1A: hcnt_next <= 5'h1B;
	5'h1B: hcnt_next <= 5'h18;
	5'h18: hcnt_next <= 5'h19;
	5'h19: hcnt_next <= 5'h1E;
	default: ;
	endcase
	//hcnt_next <= hcnt + 1'd1;
end

// hsync gen
wire hdelay_res0 = hsync_n | hdelay_reg[3]; // u804
wire hdelay_res1 = hsync_n; // u822

reg hdelay_res0_d, hdelay2d;
always @(posedge clk) begin
	hdelay_res0_d <= hdelay_res0;
	hdelay2d <= hdelay[2];
end

always @(*) begin
	hdelay = hdelay_reg;
	mode_sync_en = ~hdelay_res0_d & hdelay_res0 & hdelay2d;
	if (hdelay_res0) hdelay[2:0] = 0;
	if (hdelay_res1) hdelay[3] = 0;
end

always @(posedge clk) begin
	if (hdelay_res0 | hdelay_res1) hdelay_reg <= hdelay;
	else if (CCLK_EN_N) begin
		case (hdelay)
		4'h0: hdelay_reg <= 4'h1;
		4'h1: hdelay_reg <= 4'h6;
		4'h6: hdelay_reg <= 4'h7;
		4'h7: hdelay_reg <= 4'h4;
		4'h4: hdelay_reg <= 4'h5;
		4'h5: hdelay_reg <= 4'h8;
		default: ;
		endcase
	end
end

assign HSYNC_O = hdelay[2];

assign SYNC_N = ~(VSYNC_O ^ HSYNC_O);

//wire mode_sync = ~hdelay[2];

// interrupt counter
wire intcntclr_52; // set when intcnt=52, reset when hsync=1
wire intcnt52 = hcnt_cnt & intcnt_next[2] & intcnt_next[4] & intcnt_next[5];
rslatch #(0) intcntclr_52_l(clk, intcnt52, ~hsync_n, intcntclr_52);

wire intcntclr_4  = VSYNC_O & ~vsync_o_d; // u817
wire intcnt_res0 = intcntclr_52 | intcntclr_4 | irq_reset; // u831
wire intcnt_res1 = intcnt_res0 | irqack_rst; // u833

always @(*) begin
	intcnt = intcnt_reg;
	if (intcnt_res0) intcnt[4:0] = 0;
	else if (hcnt_cnt) intcnt = intcnt_next;
	if (intcnt_res1) intcnt[5] = 0;
end

always @(posedge clk) begin
	intcnt_reg <= intcnt;
	intcnt_next <= intcnt + 1'd1;
end

// interrupt ack/reset
rslatch irqack_rst_l(clk, ~(INT_N | IORQ_N | M1_N), M1_N, irqack_rst);
wire int_reset = irq_reset | irqack_rst;

always @(posedge clk)  begin : cnt5_block
	reg cnt5;
	cnt5 <= intcnt[5];
	// instead of async tricks, register INT_N in the main clk domain
	if (int_reset) INT_N <= 1; else if (~intcnt[5] & cnt5) INT_N <= 0; // u836
end

endmodule
