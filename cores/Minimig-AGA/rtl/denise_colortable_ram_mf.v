module denise_colortable_ram_mf (
	byteena_a,
	clock,
	data,
	enable,
	rdaddress,
	wraddress,
	wren,
	q);

	input	[3:0]  byteena_a;
	input	       clock;
	input	[31:0] data;
	input	       enable;
	input	[7:0]  rdaddress;
	input	[7:0]  wraddress;
	input	       wren;
	output	[31:0] q;

	xpm_memory_sdpram #(
		.ADDR_WIDTH_A(8),               // DECIMAL
		.ADDR_WIDTH_B(8),               // DECIMAL
		.AUTO_SLEEP_TIME(0),            // DECIMAL
		.BYTE_WRITE_WIDTH_A(8),        // DECIMAL
		.CASCADE_HEIGHT(0),             // DECIMAL
		.CLOCKING_MODE("common_clock"), // String
		.ECC_MODE("no_ecc"),            // String
		.MEMORY_INIT_FILE("none"),      // String
		.MEMORY_INIT_PARAM("0"),        // String
		.MEMORY_OPTIMIZATION("true"),   // String
		.MEMORY_PRIMITIVE("auto"),      // String
		.MEMORY_SIZE(256),              // DECIMAL
		.MESSAGE_CONTROL(0),            // DECIMAL
		.READ_DATA_WIDTH_B(32),         // DECIMAL
		.READ_LATENCY_B(1),             // DECIMAL
		.READ_RESET_VALUE_B("0"),       // String
		.RST_MODE_A("SYNC"),            // String
		.RST_MODE_B("SYNC"),            // String
		.SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
		.USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
		.USE_MEM_INIT(1),               // DECIMAL
		.USE_MEM_INIT_MMI(0),           // DECIMAL
		.WAKEUP_TIME("disable_sleep"),  // String
		.WRITE_DATA_WIDTH_A(32),        // DECIMAL
		.WRITE_MODE_B("read_first"),     // String
		.WRITE_PROTECT(1)               // DECIMAL
	 ) denise_colortable_ram_inst (
		.dbiterrb(),                     // 1-bit output: Status signal to indicate double bit error occurrence
										 // on the data output of port B.
  
		.doutb(q),                       // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
		.sbiterrb(),                     // 1-bit output: Status signal to indicate single bit error occurrence
										 // on the data output of port B.
  
		.addra(wraddress),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
		.addrb(rdaddress),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
		.clka(clock),                     // 1-bit input: Clock signal for port A. Also clocks port B when
										 // parameter CLOCKING_MODE is "common_clock".
  
		.clkb(clock),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
										 // "independent_clock". Unused when parameter CLOCKING_MODE is
										 // "common_clock".
  
		.dina(data),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
		.ena(wren),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
										 // cycles when write operations are initiated. Pipelined internally.
  
		.enb(enable),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
										 // cycles when read operations are initiated. Pipelined internally.
  
		.injectdbiterra(1'b0),           // 1-bit input: Controls double bit error injection on input data when
										 // ECC enabled (Error injection capability is not available in
										 // "decode_only" mode).
  
		.injectsbiterra(1'b0),           // 1-bit input: Controls single bit error injection on input data when
										 // ECC enabled (Error injection capability is not available in
										 // "decode_only" mode).
  
		.regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
										 // data path.
  
		.rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage.
										 // Synchronously resets output port doutb to the value specified by
										 // parameter READ_RESET_VALUE_B.
  
		.sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
		.wea(byteena_a)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
										 // for port A input data port dina. 1 bit wide when word-wide writes are
										 // used. In byte-wide write configurations, each bit controls the
										 // writing one byte of dina to address addra. For example, to
										 // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
										 // is 32, wea would be 4'b0010.
  
	 );

endmodule

