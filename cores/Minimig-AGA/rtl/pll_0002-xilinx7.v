`timescale 1ns/10ps
module  pll_0002 (
	input  wire refclk,
	input  wire rst,
	output wire outclk_0,
	output wire outclk_1,
	output wire locked
);

    wire feedback;
	wire clkout0;
	wire clkout1;
	
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT_F(27.250),
		.CLKIN1_PERIOD(20.0),
		.CLKOUT0_DIVIDE_F(12.0), // 50*27.25/12 ~= 113.541666...
		.CLKOUT0_PHASE(8'd0),
		.CLKOUT1_DIVIDE(8'd48),  // 50*27.25/48 ~= 28.38541666...
		.CLKOUT1_PHASE(8'd0),
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
		.CLKOUT1   (clkout1),
		.LOCKED    (locked)
	);

	BUFG clk_bufg0 (.I(clkout0), .O(outclk_0));
	BUFG clk_bufg1 (.I(clkout1), .O(outclk_1));

endmodule

