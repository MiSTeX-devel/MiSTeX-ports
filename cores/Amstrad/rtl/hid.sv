//============================================================================
//
// Input for Amstrad CPC
// (c) 2018 Sorgelig
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

module hid
(
	input        reset,
	input        clk,

	input [10:0] ps2_key,
	input [24:0] ps2_mouse,
	input        right_shift_mod,
	input        keypad_mod,

	input  [6:0] joystick1,
	input  [6:0] joystick2,

	input  [3:0] Y,
	output [7:0] X,
	output reg   key_nmi,
	output reg   key_reset,
	output reg [9:0] Fn
);

wire row9 = (Y == 9);
wire row6 = (Y == 6);
assign X = ~(key[Y] | joy1 | joy2 | mouse);

//================================= Joysticks ===========================================

wire [6:0] joy1 = row9 ? {joystick1[6:4], joystick1[0], joystick1[1], joystick1[2], joystick1[3]} : 7'd0;
wire [6:0] joy2 = row6 ? {joystick2[6:4], joystick2[0], joystick2[1], joystick2[2], joystick2[3]} : 7'd0;


//================================== Keyboard ===========================================

reg [7:0] key[16] = '{default:0};

wire press = ps2_key[9];
always @(posedge clk) begin
	reg old_flg, old_reset;
	reg alt = 0;

	old_flg <= ps2_key[10];
	old_reset <= reset;

	if(old_reset & ~reset) begin
		key <= '{default:0};
		Fn  <= 0;
	end

	if(old_flg ^ ps2_key[10]) begin

		if (ps2_key[8])
		case(ps2_key[7:0])
			8'h75: key[0][0] <= press; // up
			8'h74: key[0][1] <= press; // right
			8'h72: key[0][2] <= press; // down
			8'h69: key[0][6] <= press; // Enter (End)
			8'h7A: key[0][7] <= press; // . (PgDn)

			8'h6B: key[1][0] <= press; // left
			8'h70: key[1][1] <= press; // copy (Insert)
			
			8'h71: key[2][0] <= press; // CLR (DEL)
			8'h5A: key[2][2] <= press; // Enter
			8'h14: key[2][7] <= press; // Ctrl (right)

			8'h4A: key[3][6] <= press; // KP /
		endcase
		else
		case(ps2_key[7:0])
			8'h11: alt       <= press; // alt

			8'h75: // KP UP/8
				if (keypad_mod)
					key[0][0] <= press; // up
				else
					key[1][3] <= press; // F8
			8'h74: // KP RIGHT/6
				if (keypad_mod)
					key[0][1] <= press; // right
				else
					key[0][4] <= press; // F6
			8'h72: // KP DOWN/2
				if (keypad_mod)
					key[0][2] <= press; // down
				else
					key[1][6] <= press; // F2
			8'h7d: key[0][3] <= press; // KP9 - F9
			8'h01: key[0][3] <= press & ~alt; // F9
			8'h0B: key[0][4] <= press & ~alt; // F6
			8'h04: key[0][5] <= press & ~alt; // F3
			8'h69: // KP END/1
				if (keypad_mod)
					key[0][6] <= press; // Enter (End)
				else
					key[1][5] <= press; // F1
			8'h7A: // KP PgDn/3
				if (keypad_mod)
					key[0][7] <= press; // . (PgDn)
				else
					key[0][5] <= press; // F3
			8'h6B: // KP LEFT/4
				if (keypad_mod)
					key[1][0] <= press; // left
				else
					key[2][4] <= press; // F4
			8'h70: // KP INS/0
				if (keypad_mod)
					key[1][1] <= press; // copy (Insert)
				else
					key[1][7] <= press; // F0
			8'h73: // KP 5
				if (keypad_mod)
					key[1][1] <= press; // copy
				else
					key[1][4] <= press; // F5
			8'h6C: key[1][2] <= press; // KP7 - F7
			8'h83: key[1][2] <= press & ~alt; // F7
			8'h0A: key[1][3] <= press & ~alt; // F8
			8'h03: key[1][4] <= press & ~alt; // F5
			8'h05: key[1][5] <= press & ~alt; // F1
			8'h06: key[1][6] <= press & ~alt; // F2
			8'h09: key[1][7] <= press & ~alt; // F0

			8'h71: // KP ./0
				if (keypad_mod)
					key[2][0] <= press; // CLR (DEL)
				else
				   key[3][7] <= press; // .
			8'h5B: key[2][1] <= press; // [ (])
			8'h5A: key[2][2] <= press; // Enter
			8'h5D: key[2][3] <= press; // ] (\)
			8'h0C: key[2][4] <= press & ~alt; // F4
			8'h12: key[2][5] <= press; // LShift
			8'h59: // RShift
				if (right_shift_mod)
					key[2][5] <= press; // Shift
				else
					key[2][6] <= press; // \

			8'h61: key[2][6] <= press; // \

			8'h14: key[2][7] <= press; // Ctrl

			8'h55: key[3][0] <= press; // arrow (+)
			8'h7B: key[3][1] <= press; // KP -
			8'h4E: key[3][1] <= press; // -
			8'h54: key[3][2] <= press; // @ ([)
			8'h4D: key[3][3] <= press; // P
			8'h79: // KP +
				begin
					key[3][4] <= press;
					key[2][5] <= press;
				end
			8'h52: key[3][4] <= press; // ; (:)
			8'h7C: // KP *
				begin
					key[3][5] <= press;
					key[2][5] <= press;
				end
			8'h4C: key[3][5] <= press; // : (')
			8'h4A: key[3][6] <= press; // /
			8'h49: key[3][7] <= press; // .

			8'h45: key[4][0] <= press; // 0
			8'h46: key[4][1] <= press; // 9
			8'h44: key[4][2] <= press; // O
			8'h43: key[4][3] <= press; // I
			8'h4B: key[4][4] <= press; // L
			8'h42: key[4][5] <= press; // K
			8'h3A: key[4][6] <= press; // M
			8'h41: key[4][7] <= press; // ,

			8'h3E: key[5][0] <= press; // 8
			8'h3D: key[5][1] <= press; // 7
			8'h3C: key[5][2] <= press; // U
			8'h35: key[5][3] <= press; // Y
			8'h33: key[5][4] <= press; // H
			8'h3B: key[5][5] <= press; // J
			8'h31: key[5][6] <= press; // N
			8'h29: key[5][7] <= press; // SPACE

			8'h36: key[6][0] <= press; // 6
			8'h2E: key[6][1] <= press; // 5
			8'h2D: key[6][2] <= press; // R
			8'h2C: key[6][3] <= press; // T
			8'h34: key[6][4] <= press; // G
			8'h2B: key[6][5] <= press; // F
			8'h32: key[6][6] <= press; // B
			8'h2A: key[6][7] <= press; // V

			8'h25: key[7][0] <= press; // 4
			8'h26: key[7][1] <= press; // 3
			8'h24: key[7][2] <= press; // E
			8'h1D: key[7][3] <= press; // W
			8'h1B: key[7][4] <= press; // S
			8'h23: key[7][5] <= press; // D
			8'h21: key[7][6] <= press; // C
			8'h22: key[7][7] <= press; // X

			8'h16: key[8][0] <= press; // 1
			8'h1E: key[8][1] <= press; // 2
			8'h76: key[8][2] <= press; // Esc
			8'h15: key[8][3] <= press; // Q
			8'h0D: key[8][4] <= press; // Tab
			8'h1C: key[8][5] <= press; // A
			8'h58: key[8][6] <= press; // Caps Lock
			8'h1A: key[8][7] <= press; // Z

			8'h66: key[9][7] <= press; // DEL (Backspace)
			
			8'h78: begin // F11
				if (press) begin
					key_nmi   <= !alt;
					key_reset <= alt;
				end else begin
					key_nmi <= 0;
					key_reset <= 0;
				end
			end
		endcase
		
		case(ps2_key[7:0])
			8'h05: Fn[1] <= press & alt; // F1
			8'h06: Fn[2] <= press & alt; // F2
			8'h04: Fn[3] <= press & alt; // F3
			8'h0C: Fn[4] <= press & alt; // F4
			8'h03: Fn[5] <= press & alt; // F5
			8'h0B: Fn[6] <= press & alt; // F6
			8'h83: Fn[7] <= press & alt; // F7
			8'h0A: Fn[8] <= press & alt; // F8
			8'h01: Fn[9] <= press & alt; // F9
			8'h09: Fn[0] <= press & alt; // F10
		endcase;
	end
end


//=================================== Mouse =============================================

wire [6:0] mouse = row9 ? {mbtn,mdir} : 7'd0;

reg  [2:0] mbtn = 0;
wire [3:0] mdir;

mouse_axis mx(clk, mstb, {ps2_mouse[4],ps2_mouse[15:8]},  ~row9, {mdir[2], mdir[3]});
mouse_axis my(clk, mstb, {ps2_mouse[5],ps2_mouse[23:16]}, ~row9, {mdir[1], mdir[0]});

reg mstb = 0;
always @(posedge clk) begin
	reg old_status;

	old_status <= ps2_mouse[24];
	mstb <= 0;
	if(old_status != ps2_mouse[24]) begin
		mstb <= 1;
		mbtn <= ps2_mouse[2:0];
	end
end

endmodule

module mouse_axis
(
	input            clk,

	input            set,
	input [8:0]      offset,

	input            reset,
	output reg [1:0] dir
);

localparam [8:0] step = 2;

reg signed [8:0] counter;
always @(posedge clk) begin
	reg old_reset;

	if(set) counter <= offset;
	else begin
		old_reset <= reset;
	
		if(~old_reset & reset) dir <= 0;
		else if(!dir && counter) begin
			if(counter>0) begin
				dir[0] <= 1;
				if(counter > step) counter <= counter - step;
				else counter <= 0;
			end
			else begin
				dir[1] <= 1;
				if((counter + step) < 0) counter <= counter + step;
				else counter <= 0;
			end
		end
	end
end
	
endmodule
