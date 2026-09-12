import core_types::*;

module mem_wb_reg (
    input logic clk,
    input logic rst,

    input writeback_control_t writeback_control_mem_i,
    input logic [31:0] alu_result_mem_i,
    input logic [31:0] memory_read_data_mem_i,
    input logic [4:0] rd_mem_i,

    output writeback_control_t writeback_control_wb_o,
    output logic [31:0] alu_result_wb_o,
    output logic [31:0] memory_read_data_wb_o,
    output logic [4:0] rd_wb_o
);

  always_ff @(posedge clk) begin
    if (rst) begin
      writeback_control_wb_o <= '0;
      alu_result_wb_o        <= '0;
      memory_read_data_wb_o  <= '0;
      rd_wb_o                <= '0;
    end else begin
      writeback_control_wb_o <= writeback_control_mem_i;
      alu_result_wb_o        <= alu_result_mem_i;
      memory_read_data_wb_o  <= memory_read_data_mem_i;
      rd_wb_o                <= rd_mem_i;
    end
  end

endmodule
