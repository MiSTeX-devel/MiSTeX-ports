
// PlayCity expansion by TotO,
// implemented in VHDL by Slingshot
// Verilog version with some modifications by Sorgelig
// https://www.cpcwiki.eu/index.php/PlayCity

module playcity
(
   input         clock,
   input         reset,
   input         ena,
   
   input         phi_n,
   input         phi_en,
   input  [15:0] addr,
   input   [7:0] din,
   output  [7:0] dout,
   input   [7:0] cpu_di,		// for CTC RETI detection
   input         m1_n,
   input         iorq_n,
   input         rd_n,
   input         wr_n,
   output        int_n,
   output        nmi,
   
   input         cursor,
   
   output  [7:0] audio_l,
   output  [7:0] audio_r
);

// F8FF
wire soft_reset = (ena && ~iorq_n && m1_n && addr[15:0] == 16'hF8FF);
wire reset_n = ~(soft_reset | reset) & ena;

// F880-F883
wire ctc_ce_n = ~(ena && ~iorq_n && m1_n && addr[15:2] == {12'hF88, 2'b00});

// F88x: write AY data
// F98x: write AY address
// addr[2] - left, addr[3] - right
wire ay_sel = (ena && ~iorq_n && ~wr_n && addr[15:9] == {4'hF, 3'b100} && addr[7:4] == 4'h8);

// Z80-CTC (MK3882)
wire ctc_counter_0_to;
wire ctc_counter_3_trg;
z80ctc_top z80ctc
(
	.clock(clock),
	.clock_ena(phi_en),
	.reset(~reset_n),
	.din(din),
	.cpu_din(cpu_di),
	.dout(dout),
	.ce_n(ctc_ce_n),
	.cs(addr[1:0]),
	.m1_n(m1_n),
	.iorq_n(iorq_n),
	.rd_n(rd_n),
	.int_n(int_n),
	.trg0(phi_n),
	.to0(ctc_counter_0_to),
	.trg1(cursor),
	.to1(nmi),
	.trg2(phi_n),
	.to2(ctc_counter_3_trg),
	.trg3(ctc_counter_3_trg)
);

wire ay_clock = ctc_counter_0_to | phi_n;
reg  ay_ce;
always @(posedge clock) begin : ay_block
	reg ay_clock_d;

	ay_clock_d <= ay_clock;
	ay_ce <= (~ay_clock_d & ay_clock);
end

wire [9:0] al = {2'b00, chl_a} + {2'b00, chl_b} + {2'b00, chl_c};
assign audio_l = al[9:2] + al[9:4];

wire [7:0] chl_a, chl_b, chl_c;
YM2149 psg_left
(
	.RESET(~reset_n),

	.CLK(clock),
	.CE(ay_ce),
	.SEL(1),
	.MODE(0),

	.BC(addr[8]),
	.BDIR(ay_sel & addr[2]),
	.DI(din),

	.CHANNEL_A(chl_a),
	.CHANNEL_B(chl_b),
	.CHANNEL_C(chl_c)
);

wire [9:0] ar = {2'b00, chr_a} + {2'b00, chr_b} + {2'b00, chr_c};
assign audio_r = ar[9:2] + ar[9:4];

wire [7:0] chr_a, chr_b, chr_c;
YM2149 psg_right
(
	.RESET(~reset_n),

	.CLK(clock),
	.CE(ay_ce),
	.SEL(1),
	.MODE(0),

	.BC(addr[8]),
	.BDIR(ay_sel & addr[3]),
	.DI(din),

	.CHANNEL_A(chr_a),
	.CHANNEL_B(chr_b),
	.CHANNEL_C(chr_c)
);

endmodule
