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
		`define SDRAM_SHIFT "5520"
	`else
		// 96 MHz clock
		// `define SDRAM_SHIFT "-3515 ps"
		`define SDRAM_SHIFT "-5034"
	`endif
`endif

module  pll_0002(

	// interface 'refclk'
	input wire refclk,

	// interface 'reset'
	input wire rst,

	// interface 'outclk0'
	output wire outclk_0,

	// interface 'outclk1'
	output wire outclk_1,

	// interface 'outclk2'
	output wire outclk_2,

	// interface 'outclk3'
	output wire outclk_3,

	// interface 'outclk4'
	output wire outclk_4,

	// interface 'outclk5'
	output wire outclk_5,

	// interface 'locked'
	output wire locked
);

`ifdef CYCLONEV
	altera_pll #(
		.fractional_vco_multiplier("false"),
		.reference_clock_frequency("50.0 MHz"),
		.operation_mode("direct"),
		.number_of_clocks(6),
		.output_clock_frequency0("48.000000 MHz"),
		.phase_shift0("0 ps"),
		.duty_cycle0(50),
		.output_clock_frequency1("48.000000 MHz"),
		.phase_shift1(`SDRAM_SHIFT),
		.duty_cycle1(50),
		.output_clock_frequency2("24.000000 MHz"),
		.phase_shift2("0 ps"),
		.duty_cycle2(50),
		.output_clock_frequency3("6.000000 MHz"),
		.phase_shift3("0 ps"),
		.duty_cycle3(50),
		.output_clock_frequency4("96.000000 MHz"),
		.phase_shift4("0 ps"),
		.duty_cycle4(50),
		.output_clock_frequency5("96.000000 MHz"),
		.phase_shift5(`SDRAM_SHIFT),
		.duty_cycle5(50),
		.output_clock_frequency6("0 MHz"),
		.phase_shift6("0 ps"),
		.duty_cycle6(50),
		.output_clock_frequency7("0 MHz"),
		.phase_shift7("0 ps"),
		.duty_cycle7(50),
		.output_clock_frequency8("0 MHz"),
		.phase_shift8("0 ps"),
		.duty_cycle8(50),
		.output_clock_frequency9("0 MHz"),
		.phase_shift9("0 ps"),
		.duty_cycle9(50),
		.output_clock_frequency10("0 MHz"),
		.phase_shift10("0 ps"),
		.duty_cycle10(50),
		.output_clock_frequency11("0 MHz"),
		.phase_shift11("0 ps"),
		.duty_cycle11(50),
		.output_clock_frequency12("0 MHz"),
		.phase_shift12("0 ps"),
		.duty_cycle12(50),
		.output_clock_frequency13("0 MHz"),
		.phase_shift13("0 ps"),
		.duty_cycle13(50),
		.output_clock_frequency14("0 MHz"),
		.phase_shift14("0 ps"),
		.duty_cycle14(50),
		.output_clock_frequency15("0 MHz"),
		.phase_shift15("0 ps"),
		.duty_cycle15(50),
		.output_clock_frequency16("0 MHz"),
		.phase_shift16("0 ps"),
		.duty_cycle16(50),
		.output_clock_frequency17("0 MHz"),
		.phase_shift17("0 ps"),
		.duty_cycle17(50),
		.pll_type("General"),
		.pll_subtype("General")
	) altera_pll_i (
		.rst	(rst),
		.outclk	({outclk_5, outclk_4, outclk_3, outclk_2, outclk_1, outclk_0}),
		.locked	(locked),
		.fboutclk	( ),
		.fbclk	(1'b0),
		.refclk	(refclk)
	);

`else


	`ifndef ALTERA_RESERVED_QIS
	// synopsys translate_off
	`endif
		// tri0	  rst;
	`ifndef ALTERA_RESERVED_QIS
	// synopsys translate_on
	`endif

	wire [4:0] sub_wire0;
	wire  sub_wire6;
	wire [0:0] sub_wire9 = 1'h0;
	wire [4:4] sub_wire5 = sub_wire0[4:4];
	wire [3:3] sub_wire4 = sub_wire0[3:3];
	wire [2:2] sub_wire3 = sub_wire0[2:2];
	wire [1:1] sub_wire2 = sub_wire0[1:1];
	wire [0:0] sub_wire1 = sub_wire0[0:0];
	assign  outclk_0 = sub_wire1;
	assign  outclk_1 = sub_wire2;
	assign  outclk_2 = sub_wire3;
	assign  outclk_3 = sub_wire4;
	assign  outclk_4 = sub_wire5;
	assign  locked = sub_wire6;
	wire  sub_wire7 = refclk;
	wire [1:0] sub_wire8 = {sub_wire9, sub_wire7};

	altpll	altpll_component (
				.areset (rst),
				.inclk (sub_wire8),
				.clk (sub_wire0),
				.locked (sub_wire6),
				.activeclock (),
				.clkbad (),
				.clkena ({6{1'b1}}),
				.clkloss (),
				.clkswitch (1'b0),
				.configupdate (1'b0),
				.enable0 (),
				.enable1 (),
				.extclk (),
				.extclkena ({4{1'b1}}),
				.fbin (1'b1),
				.fbmimicbidir (),
				.fbout (),
				.fref (),
				.icdrclk (),
				.pfdena (1'b1),
				.phasecounterselect ({4{1'b1}}),
				.phasedone (),
				.phasestep (1'b1),
				.phaseupdown (1'b1),
				.pllena (1'b1),
				.scanaclr (1'b0),
				.scanclk (1'b0),
				.scanclkena (1'b1),
				.scandata (1'b0),
				.scandataout (),
				.scandone (),
				.scanread (1'b0),
				.scanwrite (1'b0),
				.sclkout0 (),
				.sclkout1 (),
				.vcooverrange (),
				.vcounderrange ());
	defparam
		altpll_component.bandwidth_type = "AUTO",
		altpll_component.clk0_divide_by = 25,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 24,
		altpll_component.clk0_phase_shift = "0",
		altpll_component.clk1_divide_by = 25,
		altpll_component.clk1_duty_cycle = 50,
		altpll_component.clk1_multiply_by = 48,
		altpll_component.clk1_phase_shift = `SDRAM_SHIFT,
		altpll_component.clk2_divide_by = 25,
		altpll_component.clk2_duty_cycle = 50,
		altpll_component.clk2_multiply_by = 12,
		altpll_component.clk2_phase_shift = "0",
		altpll_component.clk3_divide_by = 25,
		altpll_component.clk3_duty_cycle = 50,
		altpll_component.clk3_multiply_by = 3,
		altpll_component.clk3_phase_shift = "0",
		altpll_component.clk4_divide_by = 25,
		altpll_component.clk4_duty_cycle = 50,
		altpll_component.clk4_multiply_by = 48,
		altpll_component.clk4_phase_shift = "0",
		altpll_component.compensate_clock = "CLK0",
		altpll_component.inclk0_input_frequency = 20000,
		altpll_component.intended_device_family = "Cyclone IV GX",
		altpll_component.lpm_hint = "CBX_MODULE_PREFIX=jtframe_pll6144_0002",
		altpll_component.lpm_type = "altpll",
		altpll_component.operation_mode = "NORMAL",
		altpll_component.pll_type = "AUTO",
		altpll_component.port_activeclock = "PORT_UNUSED",
		altpll_component.port_areset = "PORT_USED",
		altpll_component.port_clkbad0 = "PORT_UNUSED",
		altpll_component.port_clkbad1 = "PORT_UNUSED",
		altpll_component.port_clkloss = "PORT_UNUSED",
		altpll_component.port_clkswitch = "PORT_UNUSED",
		altpll_component.port_configupdate = "PORT_UNUSED",
		altpll_component.port_fbin = "PORT_UNUSED",
		altpll_component.port_inclk0 = "PORT_USED",
		altpll_component.port_inclk1 = "PORT_UNUSED",
		altpll_component.port_locked = "PORT_USED",
		altpll_component.port_pfdena = "PORT_UNUSED",
		altpll_component.port_phasecounterselect = "PORT_UNUSED",
		altpll_component.port_phasedone = "PORT_UNUSED",
		altpll_component.port_phasestep = "PORT_UNUSED",
		altpll_component.port_phaseupdown = "PORT_UNUSED",
		altpll_component.port_pllena = "PORT_UNUSED",
		altpll_component.port_scanaclr = "PORT_UNUSED",
		altpll_component.port_scanclk = "PORT_UNUSED",
		altpll_component.port_scanclkena = "PORT_UNUSED",
		altpll_component.port_scandata = "PORT_UNUSED",
		altpll_component.port_scandataout = "PORT_UNUSED",
		altpll_component.port_scandone = "PORT_UNUSED",
		altpll_component.port_scanread = "PORT_UNUSED",
		altpll_component.port_scanwrite = "PORT_UNUSED",
		altpll_component.port_clk0 = "PORT_USED",
		altpll_component.port_clk1 = "PORT_USED",
		altpll_component.port_clk2 = "PORT_USED",
		altpll_component.port_clk3 = "PORT_USED",
		altpll_component.port_clk4 = "PORT_USED",
		altpll_component.port_clk5 = "PORT_UNUSED",
		altpll_component.port_clkena0 = "PORT_UNUSED",
		altpll_component.port_clkena1 = "PORT_UNUSED",
		altpll_component.port_clkena2 = "PORT_UNUSED",
		altpll_component.port_clkena3 = "PORT_UNUSED",
		altpll_component.port_clkena4 = "PORT_UNUSED",
		altpll_component.port_clkena5 = "PORT_UNUSED",
		altpll_component.port_extclk0 = "PORT_UNUSED",
		altpll_component.port_extclk1 = "PORT_UNUSED",
		altpll_component.port_extclk2 = "PORT_UNUSED",
		altpll_component.port_extclk3 = "PORT_UNUSED",
		altpll_component.self_reset_on_loss_lock = "OFF",
		altpll_component.width_clock = 5;

	// ALTPLL #(
	// 	.BANDWIDTH_TYPE("AUTO"),
	// 	.CLK0_DIVIDE_BY(10'd25),   // 48.000 MHz ~= 50 MHz * 24 / 25
	// 	.CLK0_DUTY_CYCLE(6'd50),
	// 	.CLK0_MULTIPLY_BY(10'd24),
	// 	.CLK0_PHASE_SHIFT(1'd0),

	// 	.CLK1_DIVIDE_BY(10'd25),   // 48.000 MHz  PS
	// 	.CLK1_DUTY_CYCLE(6'd50),
	// 	.CLK1_MULTIPLY_BY(10'd24),
	// 	.CLK1_PHASE_SHIFT(`SDRAM_SHIFT),

	// 	.CLK2_DIVIDE_BY(10'd25),   // 24.000 MHz
	// 	.CLK2_DUTY_CYCLE(6'd50),
	// 	.CLK2_MULTIPLY_BY(10'd12),
	// 	.CLK2_PHASE_SHIFT(1'd0),

	// 	.CLK3_DIVIDE_BY(10'd25),   // 6.000 MHz
	// 	.CLK3_DUTY_CYCLE(6'd50),
	// 	.CLK3_MULTIPLY_BY(10'd3),
	// 	.CLK3_PHASE_SHIFT(1'd0),

	// 	.CLK4_DIVIDE_BY(10'd25),   // 96.000 MHz
	// 	.CLK4_DUTY_CYCLE(6'd50),
	// 	.CLK4_MULTIPLY_BY(10'd48),
	// 	.CLK4_PHASE_SHIFT(1'd0),

	// 	.CLK5_DIVIDE_BY(10'd25),   //  96.000 MHz  PS
	// 	.CLK5_DUTY_CYCLE(6'd50),
	// 	.CLK5_MULTIPLY_BY(10'd48),
	// 	.CLK5_PHASE_SHIFT(`SDRAM_SHIFT),

	// 	.COMPENSATE_CLOCK("CLK0"),
	// 	.INCLK0_INPUT_FREQUENCY(15'd20000),
	// 	.OPERATION_MODE("NORMAL")

	// ) ALTPLL (
	// 	.ARESET(1'd0),
	// 	.CLKENA(5'd31),
	// 	.EXTCLKENA(4'd15),
	// 	.FBIN(1'd1),
	// 	.INCLK(refclk),
	// 	.PFDENA(1'd1),
	// 	.PLLENA(1'd1),
	// 	.CLK({outclk_5, outclk_4, outclk_3, outclk_2, outclk_1, outclk_0}),
	// 	.LOCKED(locked)
	// );

`endif

endmodule

