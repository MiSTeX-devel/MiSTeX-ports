////////////////////////////////////////////////////////////////////////////////
//
//  PS2-to-Kempston Mouse v2
//  (C) 2017,2018 Sorgelig
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

module kempston_mouse
(
	input        clk_sys,
	input        reset,

	input [24:0] ps2_mouse,
	
	input  [2:0] addr,
	output       sel,
	output [7:0] dout
);

assign dout = data;
assign sel  = port_sel;

reg [11:0] dx;
reg [11:0] dy;

reg  [7:0] data;
reg        port_sel;
always @* begin
	port_sel = 1;
	casex(addr)
		 3'b011: data = dx[7:0];
		 3'b111: data = dy[7:0];
		 3'bX10: data = ~{5'b00000,ps2_mouse[2], ps2_mouse[0], ps2_mouse[1]} ;
		default: {port_sel,data} = 8'hFF;
	endcase
end

always @(posedge clk_sys) begin : mouse_block
	reg old_status;
	old_status <= ps2_mouse[24];

	if(reset) begin
		dx <= 128; // dx != dy for better mouse detection
		dy <= 0;
	end
	else if(old_status != ps2_mouse[24]) begin
		dx <= dx + {{4{ps2_mouse[4]}},ps2_mouse[15:8]};
		dy <= dy + {{4{ps2_mouse[5]}},ps2_mouse[23:16]};
	end
end

endmodule
