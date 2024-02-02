module dkong_soundboard #(
	W_CLK_24576M_RATE = 24576000 // Hz
) (
	input         W_CLK_24576M,
	input         W_RESETn,
	input         use_emulated_sfx,
	input         I_DKJR,   /// 1 = Emulate Donkey Kong JR, 3 or PestPlace (async not a problem)
	input         W_W0_WE,
	input         W_W1_WE,
	input         W_CNF_EN,
	input   [6:0] W_6H_Q,
	input         W_5H_Q0,
	input   [1:0] W_4H_Q,
	input   [4:0] W_3D_Q,
	output reg [15:0] O_SOUND_DAT,
	output        O_SACK,
	output [11:0] ROM_A,
	input   [7:0] ROM_D,
	output [18:0] WAV_ROM_A,
	input   [7:0] WAV_ROM_DO
);

wire   [7:0]W_D_S_DAT;

wire    [7:0]I8035_DBI;
wire    [7:0]I8035_DBO;
wire    [7:0]I8035_PAI;
wire    [7:0]I8035_PBI;
wire    [7:0]I8035_PBO;
wire    I8035_ALE;
wire    I8035_RDn;
wire    I8035_PSENn;
reg     I8035_CLK_EN;
wire    I8035_INTn;
wire    I8035_T0;
wire    I8035_T1;
wire    I8035_RSTn;

// emulate 6 MHz crystal oscillor
localparam increment_width = 17; // increment_width = ceil(RATE_decimal_precision * 3.32192)
reg [increment_width:0] count; // one longer for overflow bit.
localparam int fraction_mutliplier = (1<<<increment_width);
// This somehow refuses to work:
localparam I8035_CLK_FRACTION = 6000000.0 / W_CLK_24576M_RATE;

always @(posedge W_CLK_24576M) begin
	count <= {1'b0, count[increment_width - 1:0]} + (increment_width + 1)'(int'(fraction_mutliplier * I8035_CLK_FRACTION));
end
assign I8035_CLK_EN = count[increment_width];

I8035IP SOUND_CPU
(
	.I_CLK(W_CLK_24576M),
	.I_CLK_EN(I8035_CLK_EN),
	.I_RSTn(I8035_RSTn),
	.I_INTn(I8035_INTn),
	.I_EA(1'b1),
	.O_PSENn(I8035_PSENn),
	.O_RDn(I8035_RDn),
	.O_WRn(),
	.O_ALE(I8035_ALE),
	.O_PROGn(),
	.I_T0(I8035_T0),
	.O_T0(),
	.I_T1(I8035_T1),
	.I_DB(I8035_DBO),
	.O_DB(I8035_DBI),
	.I_P1(8'h00),
	.O_P1(I8035_PAI),
	.I_P2(I8035_PBO),
	.O_P2(I8035_PBI)
);
assign O_SACK = I8035_PBI[4];
//-------------------------------------------------

dkong_sound Digtal_sound
(
	.I_CLK(W_CLK_24576M),
	.I_RST(W_RESETn),
	.I_DKJR(I_DKJR),
	.I8035_DBI(I8035_DBI),
	.I8035_DBO(I8035_DBO),
	.I8035_PAI(I8035_PAI),
	.I8035_PBI(I8035_PBI),
	.I8035_PBO(I8035_PBO),
	.I8035_ALE(I8035_ALE),
	.I8035_RDn(I8035_RDn),
	.I8035_PSENn(I8035_PSENn),
	.I8035_RSTn(I8035_RSTn),
	.I8035_INTn(I8035_INTn),
	.I8035_T0(I8035_T0),
	.I8035_T1(I8035_T1),
	.I_SOUND_DAT(I_DKJR ? ~W_3D_Q : {1'b1, W_3D_Q[3:0]}),
	.I_SOUND_CNT(I_DKJR ? {W_4H_Q[1],W_6H_Q[6:3],W_5H_Q0} : {2'b11,W_6H_Q[5:3],W_5H_Q0}),
	.O_SOUND_DAT(W_D_S_DAT),
	.ROM_A(ROM_A),
	.ROM_D(ROM_D)
);

//----    DAC  I/F     ------------------------

localparam SAMPLE_RATE = 48000;
localparam [9:0] clocks_per_sample = 10'(W_CLK_24576M_RATE / SAMPLE_RATE);

wire signed[15:0] W_D_S_DATB;

dkongjr_dac dac08
(
	.I_CLK(W_CLK_24576M),
	.I_DECAY_EN(~I8035_PBI[7]),
	.I_RESET_n(W_RESETn),
	.I_SND_DAT({2{~W_D_S_DAT[7],W_D_S_DAT[6:0]}}), // convert 8-bit unsigned to 16-bit signed.
	.O_SND_DAT(W_D_S_DATB)
);

// Second order low pass filter. f= 1916 Hz, Q = 0.74.
wire signed[15:0] W_D_S_DATC;
iir_2nd_order filter
(
	.clk(W_CLK_24576M),
	.reset(~W_RESETn),
	.div(clocks_per_sample),
	.A2(-18'sd26649),
	.A3(18'sd11453),
	.B1(18'sd215),
	.B2(18'sd430),
	.B3(18'sd215),
   .in(W_D_S_DATB),
	.out(W_D_S_DATC)
);

// Wav sound recored at 11025 Hz rate, 8 bit unsigned
dkong_wav_sound #(
	.CLOCK_RATE(W_CLK_24576M_RATE)
) Analog_sound (
	.I_CLK(W_CLK_24576M),
	.I_RSTn(W_RESETn),
	.I_SW(I_DKJR ? 3'b00 : {W_6H_Q[2:1],W_6H_Q[0] | use_emulated_sfx}),
	.O_ROM_AB(WAV_ROM_A)
);

reg[9:0] audio_clk_counter;
reg audio_clk_en;
always@(posedge W_CLK_24576M, negedge W_RESETn) begin
	if(!W_RESETn)begin
		audio_clk_en <= 0;
		audio_clk_counter <= 0;
	end else begin
		if(audio_clk_counter != (clocks_per_sample - 1'd1)) begin
			audio_clk_en <= 0;
			audio_clk_counter <= audio_clk_counter + 1'd1;
		end else begin
			audio_clk_en <= 1;
			audio_clk_counter <= 0;
		end
	end
end

wire signed[15:0] walk_out;
dk_walk #(
	.CLOCK_RATE(W_CLK_24576M_RATE),
	.SAMPLE_RATE(SAMPLE_RATE)
) walk (
	.clk(W_CLK_24576M),
	.I_RSTn(W_RESETn),
	.audio_clk_en(audio_clk_en),
	.walk_en(~W_6H_Q[0] & use_emulated_sfx),
	.out(walk_out)
);

//  SOUND MIXER (WAV + DIG ) -----------------------

wire signed[16:0] sound_mix =
	(I_DKJR ? 17'd0 : {{4{~WAV_ROM_DO[7]}}, WAV_ROM_DO[6:0],6'b0}) +
	{{4{W_D_S_DATC[15]}},W_D_S_DATC[14:2]} + {{6{W_D_S_DATC[15]}},W_D_S_DATC[14:4]} +
	{{2{walk_out[15]}},walk_out[14:0]};


always@(posedge W_CLK_24576M) begin
	O_SOUND_DAT <=
		sound_mix[16:15] == 2'b01 ? 16'h7FFF :
		sound_mix[16:15] == 2'b10 ? 16'h8000 :
		sound_mix[15:0];
end

endmodule
