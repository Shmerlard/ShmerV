timeunit 1ns / 1ps;

module register_file (
    input logic        clk,
    input logic [ 4:0] read_address_1_i,
    input logic [ 4:0] read_address_2_i,
    input logic        write_enable_i,
    input logic [ 4:0] write_address_i,
    input logic [31:0] write_data_i,

    output logic [31:0] read_data_1_o,
    output logic [31:0] read_data_2_o
);

  logic [31:0] registers[32];

  always_ff @(posedge clk) begin
    if (write_enable_i && write_address_i != 5'd0) begin
      registers[write_address_i] <= write_data_i;
    end
  end

  always_comb begin
    read_data_1_o = (read_address_1_i != 5'd0) ? registers[read_address_1_i] : 32'd0;
    read_data_2_o = (read_address_2_i != 5'd0) ? registers[read_address_2_i] : 32'd0;
  end

endmodule
