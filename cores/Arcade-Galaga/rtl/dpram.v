// Dual-Port Block RAM with Two Write Ports
// File: dpram.v

module dpram (
    clock_a,
    clock_b,
    wren_a,
    wren_b,
    address_a,
    address_b,
    data_a,
    data_b,
    q_a,
    q_b);

parameter  addr_width_g = 8;
parameter  data_width_g = 8;

input   clock_a,  clock_b,
        wren_a,   wren_b;
input   [addr_width_g-1:0] address_a, address_b;
input   [data_width_g-1:0]    data_a,    data_b;
output  [data_width_g-1:0]       q_a,       q_b;

BRAM_TDP_MACRO #(
.BRAM_SIZE("18Kb"), // Target BRAM: "18Kb" or "36Kb"
.DEVICE("7SERIES"), // Target device: "7SERIES"
.DOA_REG(0),
// Optional port A output register (0 or 1)
.DOB_REG(0),
// Optional port B output register (0 or 1)
.INIT_A(36'h0000000), // Initial values on port A output port
.INIT_B(36'h00000000), // Initial values on port B output port
.INIT_FILE ("NONE"),
.READ_WIDTH_A (data_width_g),
// Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
.READ_WIDTH_B (data_width_g),
// Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
.SIM_COLLISION_CHECK ("ALL"), // Collision check enable "ALL", "WARNING_ONLY","GENERATE_X_ONLY" or "NONE"
.SRVAL_A(36'h00000000), // Set/Reset value forr port A output
.SRVAL_B(36'h00000000), // Set/Reset value forr port B output
.WRITE_MODE_A("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
.WRITE_MODE_B("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
.WRITE_WIDTH_A(data_width_g), // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
.WRITE_WIDTH_B(data_width_g)  // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
) BRAM_TDP_MACRO_inst (
.DOA(q_a),
// Output port-A data, width defined by READ_WIDTH_A parameter
.DOB(q_b),
// Output port-B data, width defined by READ_WIDTH_B parameter
.ADDRA(address_a),
// Input port-A address, width defined by Port A depth
.ADDRB(address_b),
// Input port-B address, width defined by Port B depth
.CLKA(clock_a),
// 1-bit input port-A clock
.CLKB(clock_b),
// 1-bit input port-B clock
.DIA(data_a),
// Input port-A data, width defined by WRITE_WIDTH_A parameter
.DIB(data_b),
// Input port-B data, width defined by WRITE_WIDTH_B parameter
.ENA(1'b1),
// 1-bit input port-A enable
.ENB(1'b1),
// 1-bit input port-B enable
.RSTA(1'b0),
// 1-bit input port-A reset
.RSTB(1'b0),
// 1-bit input port-B reset
.WEA(wren_a),
// Input port-A write enable, width defined by Port A depth
.WEB(wren_b)
// Input port-B write enable, width defined by Port B depth
);

endmodule 