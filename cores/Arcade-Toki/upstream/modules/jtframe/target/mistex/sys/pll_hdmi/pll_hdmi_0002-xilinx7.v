`timescale 1ns/10ps
module  pll_hdmi_0002 (
	input  wire refclk,
	input  wire rst,
	output wire outclk_0,
	output wire locked,
	input  wire [63:0] reconfig_to_pll,
	output wire [63:0] reconfig_from_pll
);

	wire [15:0] din;
	wire [6:0]  daddr;
	wire [15:0] dout;
	wire        den;
	wire        dwe;
	wire        rst_mmcm;
	wire        drdy;
	wire        dclk;

	// inputs from PLL
	assign reconfig_from_pll[15:0] = dout;
	assign reconfig_from_pll[16]   = drdy;
	assign reconfig_from_pll[17]   = locked;

	// outputs to PLL
	assign din      = reconfig_to_pll[15:0];
	assign daddr    = reconfig_to_pll[22:16];
	assign den      = reconfig_to_pll[23];
	assign dwe      = reconfig_to_pll[24];
	assign rst_mmcm = reconfig_to_pll[25];
	assign dclk     = reconfig_to_pll[26];

    wire feedback;
	wire clkout0;
	
	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT_F(25.25),
		.CLKIN1_PERIOD(20.0),
		.CLKOUT0_DIVIDE_F(17), // 50*25.25/17 = 74.26470588235294
		.CLKOUT0_PHASE(1'd0),
		.DIVCLK_DIVIDE(1'd1),
		.REF_JITTER1(0.01),
		.STARTUP_WAIT("FALSE")
	) pll_hdmi_0002_inst (
		.CLKFBIN   (feedback),
		.CLKIN1    (refclk),
		.PWRDWN    (1'b0),
		.RST       (rst),
		.CLKFBOUT  (feedback),
		.CLKOUT0   (clkout0),
		.DO        (dout),
		.DRDY      (drdy),
		.DADDR     (daddr),
		.DCLK      (dclk),
		.DEN       (den),
		.DI        (din),
		.DWE       (dwe),
		.LOCKED    (locked)
	);

	BUFG clk_bufg (.I(clkout0), .O(outclk_0));

endmodule

