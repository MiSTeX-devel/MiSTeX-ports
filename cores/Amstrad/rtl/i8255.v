//============================================================================
//  Simple i82c55 implementation
//  Copyright (C) 2018 Sorgelig
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

module i8255
(
	input           reset,
	input           clk_sys,

	input     [1:0] addr,
	input     [7:0] idata,
	output reg[7:0] odata,
	input           cs,
	input           we,
	input           oe,

	input     [7:0] ipa, 
	output    [7:0] opa,
	input     [7:0] ipb, 
	output    [7:0] opb,
	input     [7:0] ipc, 
	output    [7:0] opc
);

reg [7:0] mode;
reg [7:0] opa_r;
reg [7:0] opb_r;
reg [7:0] opc_r;

assign opa      =(~mode[4] | mode[6]) ? opa_r      : 8'hFF;
assign opc[7:4] =(~mode[3])           ? opc_r[7:4] : 4'hF;
assign opb      =(~mode[1])           ? opb_r      : 8'hFF;
assign opc[3:0] =(~mode[0])           ? opc_r[3:0] : 4'hF;

reg [7:0] maskC;
always @(*) begin
	casex({mode[6:4], mode[2]})
		'b1xx0: maskC = 8'b00000111;
		'b1xx1: maskC = 8'b00000000;
		'b0110: maskC = 8'b00110111;
		'b0111: maskC = 8'b00110000;
		'b0100: maskC = 8'b11000111;
		'b0101: maskC = 8'b11000000;
		'b00x1: maskC = 8'b11111000;
	  default: maskC = 8'b11111111;
	endcase
end

//cpc quirk to pass the ppi test
wire [3:0] tapemotor = (~mode[6] & mode[5] & ~mode[4] & ~mode[2]) ? 4'h2 : 4'h0;

always @* begin
	casex({oe&cs,addr})
		'b0XX: odata = 8'hFF;
		'b100: odata =(mode[4] | mode[6]) ? ipa : opa_r;
		'b101: odata = mode[1] ? ipb : opb_r;
		'b110: odata ={mode[3] ? (ipc[7:4] & maskC[7:4]) | tapemotor : opc_r[7:4], mode[0] ? ipc[3:0] & maskC[3:0] : opc_r[3:0]};
		'b111: odata = mode;
	endcase
end

always @(posedge clk_sys) begin : op_block
	reg old_we;

	old_we <= we;
	if (reset) {opa_r,opb_r,opc_r,mode} <= {8'h00,8'h00,8'h00,8'h9B};
	else begin
		if(~old_we & we & cs) begin
			case(addr)
				0: opa_r <= idata;
				1: opb_r <= idata;
				2: opc_r <= (idata & maskC) | (opc_r & ~maskC);

				default: begin
					if (~idata[7]) opc_r[idata[3:1]] <= idata[0];
						else {opa_r,opb_r,opc_r,mode} <= {8'h00,8'h00,8'h00,idata};
				end
			endcase
		end
	end
end

endmodule
