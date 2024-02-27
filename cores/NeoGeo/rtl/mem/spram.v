module spram #(parameter ADDRWIDTH=8, DATAWIDTH=8)
(
	input	                 clock,
	input	 [ADDRWIDTH-1:0] address,
	input	 [DATAWIDTH-1:0] data,
	input	                 wren,
	output [DATAWIDTH-1:0] q
);

dpram #(ADDRWIDTH, DATAWIDTH) ram
(
	.clock_a(clock),
	.clock_b(clock),
	.address_a(address),
	.data_a(data),
	.wren_a(wren),
	.q_a(q)
);

endmodule
