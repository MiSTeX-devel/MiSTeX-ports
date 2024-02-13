// Dual-Port Block RAM with Two Write Ports
// File: dpram.v

module dpram (
    clock_a,
    clock_b,
    // enable_a,
    // enable_b,
    wren_a,
    wren_b,
    address_a,
    address_b,
    data_a,
    data_b,
    q_a,
    q_b);

parameter  ADDRWIDTH = 8;
parameter  DATAWIDTH = 8;
parameter  NUMWORDS  = 1<<ADDRWIDTH;
parameter  MEM_INIT_FILE="";

localparam addr_max = (2 ** ADDRWIDTH) - 1;

input   clock_a,  clock_b,
        // enable_a, enable_b,
        wren_a,   wren_b;
input   [ADDRWIDTH-1:0] address_a, address_b;
input   [DATAWIDTH-1:0]    data_a,    data_b;
output  [DATAWIDTH-1:0]       q_a,       q_b;

reg     [DATAWIDTH-1:0] ram [addr_max:0];
reg     [DATAWIDTH-1:0] q_a, q_b;

wire    enable_a=1'b1, enable_b=1'b1;


always @(posedge clock_a) begin
    if (enable_a) begin
        if (wren_a) begin
            ram[address_a] <= data_a;
            q_a <= data_a;
        end else
            q_a <= ram[address_a];
    end
end

always @(posedge clock_b) begin
    if (enable_b) begin
        if (wren_b) begin
            ram[address_b] <= data_b;
            q_b <= data_b;
        end else
            q_b <= ram[address_b];
    end
end

endmodule 

module spram #(parameter ADDRWIDTH=8, DATAWIDTH=8, NUMWORDS=1<<ADDRWIDTH)
(
	input	                 clock,
	input	 [ADDRWIDTH-1:0] address,
	input	 [DATAWIDTH-1:0] data,
	input	                 wren,
	output [DATAWIDTH-1:0] q
);

dpram #(ADDRWIDTH, DATAWIDTH, NUMWORDS) ram
(
	.clock_a(clock),
	.clock_b(clock),
	.address_a(address),
	.data_a(data),
	.wren_a(wren),
	.q_a(q)
);

endmodule
