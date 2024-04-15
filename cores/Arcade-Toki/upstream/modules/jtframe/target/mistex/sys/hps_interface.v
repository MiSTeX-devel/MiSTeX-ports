module hps_interface
(
    // HPS interface
    input   [15:0] gp_in,
    output  [31:0] gp_out,
    output         io_strobe,

    // HPS SPI
    input      spi_mosi,
    output reg spi_miso,
    input      spi_clk,
    input      spi_cs,

    // other HPS signals
    input fpga_enable,
    input osd_enable,
    input io_enable,

    input sys_clk,
    input reset     // not used
);

// spi_clk is used to sample mosi and generate miso
// sys_clk is used to generate io_strobe (for 1 sys_clk period)
// This allow for slow sys_clk w.r.t. spi_clk

assign gp_out = {
    11'b0,          // [31:21]
    io_enable_r,    // [20]
    osd_enable_r,   // [19]
    fpga_enable_r,  // [18]
    2'b0,           // [17:16]
    word_out        // [15:0]
};

reg io_enable_r;
reg osd_enable_r;
reg fpga_enable_r;
always @(posedge sys_clk) begin
	io_enable_r <= io_enable;
	osd_enable_r <= osd_enable;
	fpga_enable_r <= fpga_enable;
end

// count data bits and ouput data to master on spi_clk rising edge
reg [3:0]  bit_cnt;
always @(posedge spi_clk or posedge spi_cs) begin
    if (spi_cs) begin
      bit_cnt <= 0;
    end else begin
      bit_cnt <= bit_cnt + 1;
      spi_miso = gp_in[15 - bit_cnt];
    end
end

// latch data from master on spi_clk falling edge
// and signal word complete on 16th bit
reg [15:0] word_in;
reg        word_complete;
always @(negedge spi_clk or posedge spi_cs) begin
    if (spi_cs) begin
      word_complete <= 0;
    end else begin
      word_in <= { word_in[14:0], spi_mosi };

      if (bit_cnt == 0) begin
        word_complete <= 1;
      end else begin
        word_complete <= 0;
      end
    end
end

// latch final word out after 2 sys_clk delay
reg        word_complete_d1;
reg        word_complete_d2;
reg        word_complete_d3;
reg [15:0] word_out;

always @(posedge sys_clk) begin
  word_complete_d1 <= word_complete;
  word_complete_d2 <= word_complete_d1;
  word_complete_d3 <= word_complete_d2;
  if ((word_complete_d2 == 0) & (word_complete_d1 == 1)) begin
    word_out <= word_in;
  end	
end

// generate strobe after 3 sys_clk delay
// (spi cs should not be deasserted too fast)
reg rx_strobe;
always @(posedge sys_clk or posedge spi_cs) begin
    if (spi_cs) begin
      rx_strobe <=0;
    end else begin
      rx_strobe <= 0;
    if ((word_complete_d3 == 0) & (word_complete_d2 == 1)) begin
      rx_strobe <= 1;
    end
  end	
end

assign io_strobe = rx_strobe;

endmodule

