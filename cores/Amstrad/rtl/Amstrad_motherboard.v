/*

	Converted to verilog optimized and simplified
	(C) 2018 Sorgelig


--    {@{@{@{@{@{@
--  {@{@{@{@{@{@{@{@  This code is covered by CoreAmstrad synthesis r004
--  {@    {@{@    {@  A core of Amstrad CPC 6128 running on MiST-board platform
--  {@{@{@{@{@{@{@{@
--  {@  {@{@{@{@  {@  CoreAmstrad is implementation of FPGAmstrad on MiST-board
--  {@{@        {@{@   Contact : renaudhelias@gmail.com
--  {@{@{@{@{@{@{@{@   @see http://code.google.com/p/mist-board/
--    {@{@{@{@{@{@     @see FPGAmstrad at CPCWiki
--
*/

module Amstrad_motherboard
(
	input         reset,

	input         clk,
	input         ce_16,

	input   [6:0] joy1,
	input   [6:0] joy2,
	input         right_shift_mod,
	input         keypad_mod,
	input  [10:0] ps2_key,
	input  [24:0] ps2_mouse,
	output        key_nmi,
	output        key_reset,
	output  [9:0] Fn,

	input   [3:0] ppi_jumpers,
	input         crtc_type,
	input         sync_filter,
	input         no_wait,

	input         tape_in,
	output        tape_out,
	output        tape_motor,

	output  [7:0] audio_l,
	output  [7:0] audio_r,

	output  [1:0] mode,

	output  [1:0] red,
	output  [1:0] green,
	output  [1:0] blue,
	output        hblank,
	output        vblank,
	output        hsync,
	output        vsync,
	output        field,

	input  [15:0] vram_din,
	output reg [14:0] vram_addr,

	input [255:0] rom_map,
	input         ram64k,
	output [22:0] mem_addr,
	output        mem_rd,
	output        mem_wr,

	// expansion port
	output        phi_n,
	output        phi_en_n,
	output        phi_en_p,
	output [15:0] cpu_addr,
	output  [7:0] cpu_dout,
	input   [7:0] cpu_din,
	output        iorq,
	output        mreq,
	output        rd,
	output        wr,
	output        m1,
	input         irq,
	input         nmi,
	output        cursor
);

wire crtc_shift;

wire io_rd = ~(RD_n | IORQ_n);
wire io_wr = ~(WR_n | IORQ_n);

assign mem_rd = ~(RD_n | MREQ_n);
assign mem_wr = ~(WR_n | MREQ_n);

assign cpu_dout = D;
assign cpu_addr = A;
assign m1 = ~M1_n;
assign iorq = ~IORQ_n;
assign mreq = ~MREQ_n;
assign rd = ~RD_n;
assign wr = ~WR_n;

wire [15:0] A;
wire  [7:0] D;
wire RD_n;
wire WR_n;
wire MREQ_n;
wire IORQ_n;
wire RFSH_n;
wire INT_n;
wire M1_n;

T80pa CPU
(
	.reset_n(~reset),
	
	.clk(clk),
	.cen_p(phi_en_p),
	.cen_n(phi_en_n),

	.a(A),
	.do(D),
	.di(crtc_dout & ppi_dout & cpu_din),

	.rd_n(RD_n),
	.wr_n(WR_n),
	.iorq_n(IORQ_n),
	.mreq_n(MREQ_n),
	.m1_n(M1_n),
	.rfsh_n(RFSH_n),

	.busrq_n(1),
	.int_n(INT_n & ~irq),
	.nmi_n(~nmi),
	.wait_n(ready | (IORQ_n & MREQ_n) | no_wait) // workaround a bug in T80pa: should wait only in memory or io cycles
);

wire crtc_hs, crtc_vs, crtc_de;
wire [13:0] MA;
wire  [4:0] RA;
wire  [7:0] crtc_dout;

UM6845R CRTC
(
	.CLOCK(clk),
	.CLKEN(cclk_en_n),
	.nCLKEN(cclk_en_p),
	.nRESET(~reset),
	.CRTC_TYPE(crtc_type),

	.ENABLE(io_rd | io_wr),
	.nCS(A[14]),
	.R_nW(A[9]),
	.RS(A[8]),
	.DI(~RD_n ? 8'hFF : D),
	.DO(crtc_dout),

	.VSYNC(crtc_vs),
	.HSYNC(crtc_hs),
	.DE(crtc_de),
	.FIELD(field),
	.CURSOR(cursor),

	.MA(MA),
	.RA(RA)
);

wire [14:0] crtc_vram_addr = {MA[13:12], RA[2:0], MA[9:0]};

reg vram_bs;
reg [7:0] vram_d;
reg [7:0] vram_din_shift;
always @(posedge clk) begin : vram_block
	// simulate two 8-bit fetches in the vram cycle
	reg cas_n_old;
	cas_n_old <= cas_n;
	if (!cpu_n) vram_bs <= 0;
	else begin
		vram_addr <= crtc_vram_addr;
		if (!ras_n & !cas_n_old & cas_n) vram_bs <= 1;
		if (!ras_n & !cas_n)
			if (sync_filter & crtc_shift) begin
				if (vram_bs) vram_din_shift <= crtc_de ? vram_din[15:8] : 8'd0;
				vram_d <= vram_bs ? vram_din[7:0] : vram_din_shift;
			end else
				vram_d <= vram_bs ? vram_din[15:8] : vram_din[7:0];
	end
end

wire cclk_en_n, cclk_en_p;
wire e244_n, cpu_n, ras_n, cas_n;
wire [7:0] ga_din = e244_n ? vram_d : D;
wire ready;
wire romen_n;

wire hsync_ga, hsync_filtered;
wire vsync_ga, vsync_filtered;

wire hblank_filtered;
wire vblank_ga, vblank_filtered;

assign hsync = sync_filter ? hsync_filtered : hsync_ga;
assign vsync = sync_filter ? vsync_filtered : vsync_ga;
assign hblank = sync_filter ? hblank_filtered : crtc_hs;
assign vblank = sync_filter ? vblank_filtered : vblank_ga;

crt_filter crt_filter
(
	.CLK(clk),
	.CE_4(phi_en_n),
	.HSYNC_I(crtc_hs),
	.VSYNC_I(crtc_vs),
	.HSYNC_O(hsync_filtered),
	.VSYNC_O(vsync_filtered),
	.HBLANK(hblank_filtered),
	.VBLANK(vblank_filtered),
	.SHIFT(crtc_shift)
);

ga40010 GateArray (
	.clk(clk),
	.cen_16(ce_16),
	.fast(no_wait),
	.RESET_N(~reset),
	.A(A[15:14]),
	.D(ga_din),
	.MREQ_N(MREQ_n),
	.M1_N(M1_n),
	.RD_N(RD_n),
	.IORQ_N(IORQ_n),
	.HSYNC_I(crtc_hs),
	.VSYNC_I(crtc_vs),
	.DISPEN(crtc_de),
	.CCLK(),
	.CCLK_EN_P(cclk_en_p),
	.CCLK_EN_N(cclk_en_n),
	.PHI_N(phi_n),
	.PHI_EN_N(phi_en_n),
	.PHI_EN_P(phi_en_p),
	.RAS_N(ras_n),
	.CAS_N(cas_n),
	.READY(ready),
	.CASAD_N(),
	.CPU_N(cpu_n),
	.MWE_N(),
	.E244_N(e244_n),
	.ROMEN_N(romen_n),
	.RAMRD_N(),
	.HSYNC_O(hsync_ga),
	.VSYNC_O(vsync_ga),
	.VBLANK(vblank_ga),
	.MODE(mode),
	.SYNC_N(),
	.INT_N(INT_n),
	.BLUE_OE_N(blue[0]),
	.BLUE(blue[1]),
	.GREEN_OE_N(green[0]),
	.GREEN(green[1]),
	.RED_OE_N(red[0]),
	.RED(red[1])
);

Amstrad_MMU MMU
(
	.CLK(clk),
	.reset(reset),
	.ram64k(ram64k),
	.romen_n(romen_n),
	.rom_map(rom_map),
	.A(A),
	.D(D),
	.io_WR(io_wr),
	.ram_A(mem_addr)
);

wire [7:0] ppi_dout;
wire [7:0] portC;
wire [7:0] portAout;
wire [7:0] portAin;

i8255 PPI
(
	.reset(reset),
	.clk_sys(clk),

	.addr(A[9:8]),
	.idata(D),
	.odata(ppi_dout),
	.cs(~A[11]),
	.we(io_wr),
	.oe(io_rd),

	.ipa(portAin), 
	.opa(portAout),
	.ipb({tape_in, 2'b11, ppi_jumpers, crtc_vs}),
	.opb(),
	.ipc(8'hFF), 
	.opc(portC)
);

assign tape_motor = portC[4];
assign tape_out   = portC[5];

assign audio_l = {1'b0, ch_a[7:1]} + {2'b00, ch_b[7:2]};
assign audio_r = {1'b0, ch_c[7:1]} + {2'b00, ch_b[7:2]};

wire [7:0] ch_a, ch_b, ch_c;
YM2149 PSG
(
	.RESET(reset),

	.CLK(clk),
	.CE(cclk_en_p),
	.SEL(0),
	.MODE(0),

	.BC(portC[6]),
	.BDIR(portC[7]),
	.DI(portAout),
	.DO(portAin),

	.CHANNEL_A(ch_a),
	.CHANNEL_B(ch_b),
	.CHANNEL_C(ch_c),

	.IOA_in(kbd_out),
	.IOB_in(8'hFF)
);

wire [7:0] kbd_out;
hid HID
(
	.reset(reset),
	.clk(clk),
	
	.right_shift_mod(right_shift_mod),
	.keypad_mod(keypad_mod),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),

	.joystick1(joy1),
	.joystick2(joy2),

	.Y(portC[3:0]),
	.X(kbd_out),
	.key_nmi(key_nmi),
	.key_reset(key_reset),
	.Fn(Fn)
);

endmodule
