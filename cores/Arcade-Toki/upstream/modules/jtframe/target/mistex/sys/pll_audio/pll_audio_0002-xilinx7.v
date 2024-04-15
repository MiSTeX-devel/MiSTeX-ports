`timescale 1ns/10ps
module  pll_audio_0002 (
	input  wire refclk,
	input  wire rst,
	output wire outclk_0,
	output wire locked
);

    wire feedback;
	wire clkout0;

	PLLE2_ADV #(
		.CLKFBOUT_MULT(7'd29),
		.CLKIN1_PERIOD(20.0),
		.CLKOUT0_DIVIDE(7'd59), // 50*29/59 = 24.576271186440678
		.CLKOUT0_PHASE(1'd0),
		.DIVCLK_DIVIDE(1'd1),
		.REF_JITTER1(0.01),
		.STARTUP_WAIT("FALSE")
	) pll_audio_0002_inst (
		.CLKFBIN(feedback),
		.CLKIN1(refclk),
		.PWRDWN(1'b0),
		.RST(rst),
		.CLKFBOUT(feedback),
		.CLKOUT0(clkout0),
		.LOCKED(locked)
	);

	BUFG clk_bufg (.I(clkout0), .O(outclk_0));
endmodule

