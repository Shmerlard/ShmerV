timeunit 1ns / 1ps;

module program_counter (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [31:0] next_pc,
    output logic [31:0] pc_out
);
  always_ff @(posedge clk) begin
    if (rst) begin
      pc_out <= '0;
    end else begin
      if (enable) begin
        pc_out <= next_pc;
      end
    end
  end
endmodule
