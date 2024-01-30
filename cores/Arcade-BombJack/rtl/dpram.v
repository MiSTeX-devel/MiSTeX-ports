// Dual-Port Block RAM with Two Write Ports
// File: dpram.v

module dpram (
    clock_a,
    clock_b,
    enable_a,
    enable_b,
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
localparam addr_max = (2 ** addr_width_g) - 1;

input   clock_a,  clock_b,
        enable_a, enable_b,
        wren_a,   wren_b;
input   [addr_width_g-1:0] address_a, address_b;
input   [data_width_g-1:0]    data_a,    data_b;
output  [data_width_g-1:0]       q_a,       q_b;

reg     [data_width_g-1:0] ram [addr_max:0];
reg     [data_width_g-1:0] q_a, q_b;

always @(posedge clock_a) begin
    if (enable_a) begin
        if (wren_a) begin
            ram[address_a] <= data_a;
            q_a <= data_a;
        end else
            q_a <= ram[address_a];
    end
end

always @(posedge clock_b) begin
    if (enable_b) begin
        if (wren_b) begin
            ram[address_b] <= data_b;
            q_b <= data_b;
        end else
            q_b <= ram[address_b];
    end
end

endmodule 