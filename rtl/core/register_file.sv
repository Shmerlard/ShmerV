timeunit 1ns / 1ps;

module register_file (
    input logic        clk,
    input logic [ 4:0] read_addr_1,
    input logic [ 4:0] read_addr_2,
    input logic        write_enable,
    input logic [ 4:0] write_addr,
    input logic [31:0] write_data,

    output logic [31:0] read_data_1,
    output logic [31:0] read_data_2
);

  logic [31:0] registers[32];

  always_ff @(posedge clk) begin
    if (write_enable && write_addr != 5'd0) begin
      registers[write_addr] <= write_data;
    end
  end

  always_comb begin
    read_data_1 = (read_addr_1 != 5'd0) ? registers[read_addr_1] : 32'd0;
    read_data_2 = (read_addr_2 != 5'd0) ? registers[read_addr_2] : 32'd0;
  end

endmodule
