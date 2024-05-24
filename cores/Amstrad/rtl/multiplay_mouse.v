////////////////////////////////////////////////////////////////////////////////
//
//  Multiplay Mouse
//  (C) 2018 Sorgelig
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
////////////////////////////////////////////////////////////////////////////////

module multiplay_mouse
(
	input        clk_sys,
	input        reset,

	input [24:0] ps2_mouse,

	input        sel,
	input  [2:0] addr,
	output [7:0] dout
);

assign dout = data;
reg [7:0] data;

wire signed [8:0] dxp = {ps2_mouse[4],ps2_mouse[15:8]};
wire signed [7:0] dx  = (dxp > 7) ? 8'd7 : (dxp < -8) ? -8'd8 : dxp[7:0];

wire signed [8:0] dyp = -{ps2_mouse[5],ps2_mouse[23:16]};
wire signed [7:0] dy  = (dyp > 7) ? 8'd7 : (dyp < -8) ? -8'd8 : dyp[7:0];

always @(posedge clk_sys) begin : mouse_block
	reg [1:0] avail;
	reg old_status, old_sel;

	old_status <= ps2_mouse[24];
	if(old_status != ps2_mouse[24]) avail <= 3;

	old_sel <= sel;
	if(~old_sel & sel) begin
		case(addr)
			 0: data <= {1'b0,ps2_mouse[2:0],4'b0000};
			 2: if(avail[0]) {avail[0], data} <= {1'b0, dx}; else data <= 0;
			 3: if(avail[1]) {avail[1], data} <= {1'b0, dy}; else data <= 0;
			default: data <= 8'hFF;
		endcase
	end

	if(~sel)	data <= 8'hFF;
	if(reset) avail <= 0;
end

endmodule
