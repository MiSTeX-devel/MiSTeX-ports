module top_crg (
    input  INCLK,
    output FPGA_CLK1_50,
    output FPGA_CLK2_50,
    output FPGA_CLK3_50,
    output CLK_100,
    output clk_audio
);


`ifdef ALTERA
ALTPLL #(
    .BANDWIDTH_TYPE("AUTO"),
    .CLK0_DIVIDE_BY(8'd12),
    .CLK0_DUTY_CYCLE(6'd50),
    .CLK0_MULTIPLY_BY(5'd12),
    .CLK0_PHASE_SHIFT(1'd0),
    .CLK1_DIVIDE_BY(8'd12),
    .CLK1_DUTY_CYCLE(6'd50),
    .CLK1_MULTIPLY_BY(5'd12),
    .CLK1_PHASE_SHIFT(1'd0),
    .CLK2_DIVIDE_BY(8'd12),
    .CLK2_DUTY_CYCLE(6'd50),
    .CLK2_MULTIPLY_BY(5'd12),
    .CLK2_PHASE_SHIFT(1'd0),
    .CLK3_DIVIDE_BY(8'd12),
    .CLK3_DUTY_CYCLE(6'd50),
    .CLK3_MULTIPLY_BY(5'd24),
    .CLK3_PHASE_SHIFT(1'd0),
    .CLK4_DIVIDE_BY(8'd53),
    .CLK4_DUTY_CYCLE(6'd50),
    .CLK4_MULTIPLY_BY(5'd26),
    .CLK4_PHASE_SHIFT(1'd0),
    .COMPENSATE_CLOCK("CLK0"),
    .INCLK0_INPUT_FREQUENCY(24'd20000),
    .OPERATION_MODE("NORMAL")
) top_pll (
    .INCLK(INCLK),
    .ARESET(1'd0),
    .CLKENA(5'd31),
    .EXTCLKENA(4'd15),
    .FBIN(1'd1),
    .PFDENA(1'd1),
    .PLLENA(1'd1),
    .CLK({ clk_audio, CLK_100, FPGA_CLK3_50, FPGA_CLK2_50, FPGA_CLK1_50 }),
    .LOCKED()
);
`endif

`ifdef XILINX
    wire feedback;
    wire in_clk;
    wire out_clk;

    IBUF  ibuf_inst  (.I(INCLK), .O(in_clk));

    PLLE2_ADV #(
        .CLKFBOUT_MULT(6'd32),
        .CLKIN1_PERIOD(20.0),
        .CLKOUT0_DIVIDE(6'd32),
        .CLKOUT0_PHASE(1'd0),
        .CLKOUT1_DIVIDE(6'd16),
        .CLKOUT1_PHASE(1'd0),
        .DIVCLK_DIVIDE(1'd1),
        .REF_JITTER1(0.01),
        .STARTUP_WAIT("FALSE")
    ) PLLE2_ADV (
        .CLKFBIN(feedback),
        .CLKIN1(in_clk),
        .PWRDWN(1'b0),
        .RST(1'b0),
        .CLKFBOUT(feedback),
        .CLKOUT0(out_clk),
        .CLKOUT1(CLK_100),
        .LOCKED()
    );

    BUFG clk_bufg1 (.I(out_clk), .O(FPGA_CLK1_50));
    BUFG clk_bufg2 (.I(out_clk), .O(FPGA_CLK2_50));
    BUFG clk_bufg3 (.I(out_clk), .O(FPGA_CLK3_50));
`endif
endmodule
