//
// Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
// SPDX-License-Identifier: GPL-2.0+
//
`timescale 1ps/1ps

`ifdef XILINX
module xilinx_pll_reconfig_top (
    input wire mgmt_clk,
    input wire mgmt_reset,

    // PLL ports
    output  wire [63:0] reconfig_to_pll,
    input   wire [63:0] reconfig_from_pll,

    // configuration interface: avalon-MM slave
    output      reg  [31:0] mgmt_readdata,
    input       wire [31:0] mgmt_writedata,
    output      wire        mgmt_waitrequest,
    input       wire [5:0]  mgmt_address,
    input       wire        mgmt_read,
    input       wire        mgmt_write
);

wire [15:0] din;
wire [6:0]  daddr;
wire [15:0] dout;
wire        den;
wire        dwe;
wire        rst_mmcm;
wire        drdy;
wire        locked;

// inputs from PLL
assign dout   = reconfig_from_pll[15:0];
assign drdy   = reconfig_from_pll[16];
assign locked = reconfig_from_pll[17];

// outputs to PLL
assign reconfig_to_pll[15:0]  = din;
assign reconfig_to_pll[22:16] = daddr;
assign reconfig_to_pll[23]    = den;
assign reconfig_to_pll[24]    = dwe;
assign reconfig_to_pll[25]    = rst_mmcm;
assign reconfig_to_pll[26]    = mgmt_clk; // dclk

localparam MODE_REGISTER_ADDRESS   = 6'b000000;
localparam STATUS_REGISTER_ADDRESS = 6'b000001;
localparam START_REGISTER_ADDRESS  = 6'b000010;
localparam N_COUNTER_ADDRESS       = 6'b000011;
localparam M_COUNTER_ADDRESS       = 6'b000100;
localparam C_COUNTER_ADDRESS       = 6'b000101;
localparam K_ADDRESS               = 6'b000111;

reg mode;

wire reconfig_ready;
reg  start_reconfig;
assign mgmt_waitrequest = mode ? 1'b0 : ~reconfig_ready;

reg [17:0] M, N; // M: FB Multiplier; N: prescaler
reg [22:0] C;    // C: clockout divider
reg [31:0] K;    // K: fractional divider 32 bit fixed point fractional .b31b30b29..b0

always @(posedge(mgmt_clk)) begin
    if (mgmt_reset) begin
        mode <= 0;
        start_reconfig <= 1'b0;
        M <= 18'h10000; // bypass = factor 1
        N <= 18'h10000; // bypass = factor 1
        C <= 23'h10000; // bypass = factor 1
        K <= 32'h00000001;
    end else begin
        if (mgmt_write) begin
            start_reconfig <= 1'b0;
            case (mgmt_address)
                MODE_REGISTER_ADDRESS:  mode <= mgmt_writedata[0];
                M_COUNTER_ADDRESS:      M <= mgmt_writedata[17:0];
                N_COUNTER_ADDRESS:      N <= mgmt_writedata[17:0];
                C_COUNTER_ADDRESS:      C <= mgmt_writedata[22:0];
                K_ADDRESS:              K <= mgmt_writedata;
                START_REGISTER_ADDRESS: start_reconfig <= 1'b1;
            endcase
        end else if (mgmt_read) begin
            case (mgmt_address)
                STATUS_REGISTER_ADDRESS: mgmt_readdata <= { 31'd0, reconfig_ready };
                MODE_REGISTER_ADDRESS:   mgmt_readdata <= { 31'd0, mode };
                default:                 mgmt_readdata <=   32'd0;
            endcase
        end
    end
end

wire       c_disabled;
wire       m_disabled;
wire       m_is_odd;
wire [5:0] m_high;
wire [5:0] m_low;

assign c_disabled = C[16];
assign m_disabled = M[16];
assign m_is_odd   = M[17];
assign m_high     = M[13:8];
assign m_low      = M[5:0];

wire [5:0] fbout_high;
wire [5:0] fbout_low;
wire [2:0] frac;
wire       frac_lower_half;
wire       frac_is_nonzero;

// subtract one from the M multiplier if frac is zero, to compensate for Xilinx weirdness
assign fbout_high       = frac_is_nonzero ? m_high : m_is_odd ? m_high - 1 : m_high;
assign fbout_low        = frac_is_nonzero ? m_low  : m_is_odd ? m_low      : m_low - 1;
assign frac             = K[31:29];
assign frac_lower_half  = ~frac[2];
assign frac_is_nonzero  = frac > 3'b000;

xilinx7_mmcm_reconfig xilinx7_reconfig_inst (
    .rst(mgmt_reset),
    .locked(locked),

    // CLKOUT0
    .CLKOUT0_HIGH_TIME  (c_disabled ? 6'd1 : C[13:8]),
    .CLKOUT0_LOW_TIME   (c_disabled ? 6'd1 : C[5:0]),
    .CLKOUT0_PHASE_MUX  (3'd0),
    .CLKOUT0_FRAC_EN    (1'b0),
    .CLKOUT0_EDGE       (C[17]),
    .CLKOUT0_NO_COUNT   (c_disabled),
    .CLKOUT0_DELAY_TIME (6'd0),

    .CLKOUT1_NO_COUNT   (1'b1),
    .CLKOUT2_NO_COUNT   (1'b1),
    .CLKOUT3_NO_COUNT   (1'b1),
    .CLKOUT4_NO_COUNT   (1'b1),
    .CLKOUT5_NO_COUNT   (1'b1),
    .CLKOUT6_NO_COUNT   (1'b1),

    // CLKFBOUT
    .CLKFBOUT_HIGH_TIME  (m_disabled ? 6'd1 : fbout_high),
    .CLKFBOUT_LOW_TIME   (m_disabled ? 6'd1 : fbout_low),
    .CLKFBOUT_PHASE_MUX  (3'd0),
    .CLKFBOUT_FRAC       (frac),
    .CLKFBOUT_FRAC_EN    (1'b1),
    .CLKFBOUT_WF_R       (1'b0),
    .CLKFBOUT_WF_F       (frac_lower_half),
    .CLKFBOUT_EDGE       (1'b0),
    .CLKFBOUT_NO_COUNT   (m_disabled),
    .CLKFBOUT_DELAY_TIME (6'b0),

    // DIVCLK
    .DIVCLK_HIGH_TIME (N[16] ? 6'd1 : N[13:8]),
    .DIVCLK_LOW_TIME  (N[16] ? 6'd1 : N[5:0]),
    .DIVCLK_EDGE      (N[17]),
    .DIVCLK_NO_COUNT  (N[16]),

    // reconfiguration bus
    .dclk     (mgmt_clk),
    .din      (din),
    .daddr    (daddr),
    .dout     (dout),
    .den      (den),
    .dwe      (dwe),
    .rst_mmcm (rst_mmcm),
    .drdy     (drdy),

    // activation
    .ready          (reconfig_ready),
    .start_reconfig (start_reconfig),
    .reconfig_done  ()
);

endmodule
`endif // XILINX