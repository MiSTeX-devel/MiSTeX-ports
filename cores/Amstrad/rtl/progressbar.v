/*
	A simple progressbar overlay
*/

module progressbar (
	input        clk,
	input        ce_pix,
	input        hblank,
	input        vblank,
	input        enable,
	input [24:0] current,
	input [24:0] max,
	output       pix
);

parameter X_OFFSET = 11'd68;
parameter Y_OFFSET = 11'd20;

reg [7:0] progress;
/*
always @(posedge clk) begin
	progress <= current / max[24:7];
end
*/
// Without divider
reg [24:0] prg_counter = 0;
reg  [7:0] prg_iter = 0;
always @(posedge clk) begin
	if (prg_counter >= current) begin
		progress <= prg_iter;
		prg_counter <= 0;
		prg_iter <= 0;
	end else begin
		prg_counter <= prg_counter + max[24:7];
		prg_iter <= prg_iter + 1'd1;
	end
end

// horizontal counter
reg  [10:0] h_cnt;

// vertical counter
reg  [10:0] v_cnt;

always @(posedge clk) begin : hblank_block
	reg hbD;

	if(ce_pix) begin
		hbD <= hblank;

		if(hblank) begin
			h_cnt <= 0;
			if (!hbD) v_cnt <= v_cnt + 1'd1;
		end else
			h_cnt <= h_cnt + 1'd1;

		if(vblank) v_cnt <= 0;
	end
end

// area in which OSD is being displayed
wire [10:0] h_osd_start = X_OFFSET;
wire [10:0] h_osd_end   = h_osd_start + 8'd134;
wire [10:0] v_osd_start = Y_OFFSET;
wire [10:0] v_osd_end   = v_osd_start + 8'd8;

wire [10:0] osd_hcnt    = h_cnt - h_osd_start;
wire  [3:0] osd_vcnt    = v_cnt - v_osd_start;
reg         osd_de;
reg         osd_pixel;

always @(posedge clk) begin
	if(ce_pix) begin
		case (osd_vcnt)
		0,7: osd_pixel <= 1;
		2,3,4,5: osd_pixel <= osd_hcnt == 0 || osd_hcnt == 132 || ((osd_hcnt - 2'd2) < progress);
		default: osd_pixel <= osd_hcnt == 0 || osd_hcnt == 132;
		endcase

		osd_de <=
		    (h_cnt >= h_osd_start) && ((h_cnt + 1'd1) < h_osd_end) &&
		    (v_cnt >= v_osd_start) && (v_cnt < v_osd_end);
	end
end

assign pix = enable & osd_pixel & osd_de;

endmodule
