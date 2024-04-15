`timescale 1ns/10ps
`ifndef SDRAM_SHIFT
// 5ns works with both 32 and 128 MB modules
// valid values for 48 MHz
// 0 260 520 729 1041 1250 1475 1736 1996 2256 2500 2734 2994 3255 3515 3750 3993
// 4253 4513 4774 5000 5208 5520 5729 5989 6250 6510 6770 6979 7291 7500 7725 7986
// 8246 8506 8750 8984 9244 9505 9765 10000 10243 10329

// valid values for 96 MHz
// 0 -520 -1041 -1475 -1996 -2517 -2994 -3515 -3993 -4253 -4513 -4774 -5034
// -5208 (-180 deg)

	`ifndef JTFRAME_SDRAM96
		// 48 MHz clock
		`define SDRAM_SHIFT "90"
		// `define SDRAM_SHIFT "5520 ps"
	`else
		// 96 MHz clock
		`define SDRAM_SHIFT "-180"
		//`define SDRAM_SHIFT "-5034"
	`endif
`endif


module  pll_0002(
	input wire refclk,
	input wire rst,
	output wire outclk_0,
	output wire outclk_1,
	output wire outclk_2,
	output wire outclk_3,
	output wire outclk_4,
	output wire outclk_5,		
	output wire locked
);

  // Input buffering
  //------------------------------------
  wire clk_in1_clk_wiz_0;
  IBUF clkin1_ibufg
   (.O (clk_in1_clk_wiz_0),
    .I (refclk));

  // Clocking PRIMITIVE
  //------------------------------------

  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused

  wire        outclk_0_clk_wiz_0;
  wire        outclk_1_clk_wiz_0;
  wire        outclk_2_clk_wiz_0;
  wire        outclk_3_clk_wiz_0;
  wire        outclk_4_clk_wiz_0;
  wire        outclk_5_clk_wiz_0;

  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_0;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;

// outclk_0__48.00000______0.000____________50.0______
// outclk_1__48.00000______SDRAM_SHIFT______50.0______
// outclk_2__24.00000____  0.000____________50.0______
// outclk_3___6.00000____  0.000____________50.0______
// outclk_4__96.00000____  0.000____________50.0______
// outclk_5__96.00000____  SDRAM_SHIFT______50.0______


  MMCME2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT_F      (16.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    //
    .CLKOUT0_DIVIDE_F     (16),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    //
    .CLKOUT1_DIVIDE       (16),
    .CLKOUT1_PHASE        (`SDRAM_SHIFT),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    //
    .CLKOUT2_DIVIDE       (32),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  ("FALSE"),
    //
    .CLKOUT3_DIVIDE       (128),
    .CLKOUT3_PHASE        (0.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKOUT3_USE_FINE_PS  ("FALSE"),
    //
    .CLKOUT4_DIVIDE       (8),
    .CLKOUT4_PHASE        (0.000),
    .CLKOUT4_DUTY_CYCLE   (0.500),
    .CLKOUT4_USE_FINE_PS  ("FALSE"),
    //    
    .CLKOUT5_DIVIDE       (8),
    .CLKOUT5_PHASE        (`SDRAM_SHIFT),
    .CLKOUT5_DUTY_CYCLE   (0.500),
    .CLKOUT5_USE_FINE_PS  ("FALSE"),
    //
    .CLKIN1_PERIOD        (20.833))

  mmcm_adv_inst
    // Output clocks
   (
    .CLKFBOUT            (clkfbout_clk_wiz_0),
    .CLKFBOUTB           (),
    .CLKOUT0             (outclk_0_clk_wiz_0),
    .CLKOUT0B            (),
    .CLKOUT1             (outclk_1_clk_wiz_0),
    .CLKOUT1B            (),
    .CLKOUT2             (outclk_2_clk_wiz_0),
    .CLKOUT2B            (),
    .CLKOUT3             (outclk_3_clk_wiz_0),
    .CLKOUT3B            (),
    .CLKOUT4             (outclk_4_clk_wiz_0),
    .CLKOUT4B            (),
    .CLKOUT5             (outclk_5_clk_wiz_0),
    .CLKOUT5B            (),
    .CLKOUT6             (),
     // Input clock control
    .CLKFBIN             (clkfbout_clk_wiz_0),
    .CLKIN1              (clk_in1_clk_wiz_0),
    .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
    .CLKINSEL            (1'b1),
    // Ports for dynamic reconfiguration
    .DADDR               (7'h0),
    .DCLK                (1'b0),
    .DEN                 (1'b0),
    .DI                  (16'h0),
    .DO                  (do_unused),
    .DRDY                (drdy_unused),
    .DWE                 (1'b0),
    // Ports for dynamic phase shift
    .PSCLK               (1'b0),
    .PSEN                (1'b0),
    .PSINCDEC            (1'b0),
    .PSDONE              (psdone_unused),
    // Other control and status signals
    .LOCKED              (locked_int),
    .CLKINSTOPPED        (clkinstopped_unused),
    .CLKFBSTOPPED        (clkfbstopped_unused),
    .PWRDWN              (1'b0),
    .RST                 (rst));

  assign locked = locked_int;
// Clock Monitor clock assigning
//--------------------------------------
 // Output buffering
  //-----------------------------------

  BUFG boutclk_0 (
    .O(outclk_0),
    .I(outclk_0_clk_wiz_0)
    );

  BUFG bclkout1 (
   .O(outclk_1),
   .I(outclk_1_clk_wiz_0)
   );

  BUFG bclkout2 (
   .O(outclk_2),
   .I(outclk_2_clk_wiz_0)
   );

  BUFG bclkout3 (
   .O(outclk_3),
   .I(outclk_3_clk_wiz_0)
   );

   BUFG bclkout4 (
    .O(outclk_4),
    .I(outclk_4_clk_wiz_0)
    );   

	BUFG bclkout5 (
	.O(outclk_5),
	.I(outclk_5_clk_wiz_0)
	);   
	
endmodule