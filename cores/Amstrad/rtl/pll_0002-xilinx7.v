`timescale 1ns/10ps
module  pll_0002 (
	input  wire refclk,
	input  wire rst,
	output wire outclk_0,
	output wire locked
);

    wire feedback;
	wire clkout0;
	
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT_F(20.0),
		.CLKIN1_PERIOD(20.0),
		.CLKOUT0_DIVIDE_F(15.625), // 50*20/15.625 == 64Mhz
		.CLKOUT0_PHASE(8'd0),
		.DIVCLK_DIVIDE(8'd1),
		.REF_JITTER1(0.01),
		.STARTUP_WAIT("FALSE")
	) pll_0002_inst (
		.CLKFBIN   (feedback),
		.CLKIN1    (refclk),
		.PWRDWN    (1'b0),
		.RST       (rst),
		.CLKFBOUT  (feedback),
		.CLKOUT0   (clkout0),
		.LOCKED    (locked)
	);

	BUFG clk_bufg0 (.I(clkout0), .O(outclk_0));

endmodule

