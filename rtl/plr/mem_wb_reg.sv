import core_types::*;

module mem_wb_reg (
    input logic clk,
    input logic rst,

    input logic valid_mem_i,
    input writeback_control_t writeback_control_mem_i,
    input logic [31:0] alu_result_mem_i,
    input logic [31:0] pc_plus_4_mem_i,
    input logic [31:0] dmemory_load_data_mem_i,
    input logic [4:0] rd_mem_i,
    input logic [31:0] csr_load_data_i,

    output writeback_control_t writeback_control_wb_o,
    output logic valid_wb_o,
    output logic [31:0] alu_result_wb_o,
    output logic [31:0] pc_plus_4_wb_o,
    output logic [31:0] dmemory_load_data_wb_o,
    output logic [4:0] rd_wb_o,
    output logic [31:0] csr_load_data_wb_o
);

  assign dmemory_load_data_wb_o = dmemory_load_data_mem_i;
  // assign csr_load_data_wb_o = csr_load_data_i;

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_wb_o             <= 1'b0;
      writeback_control_wb_o <= '0;
      alu_result_wb_o        <= '0;
      pc_plus_4_wb_o         <= '0;
      rd_wb_o                <= '0;
      csr_load_data_wb_o     <= '0;
    end else begin
      valid_wb_o             <= valid_mem_i;
      writeback_control_wb_o <= writeback_control_mem_i;
      alu_result_wb_o        <= alu_result_mem_i;
      pc_plus_4_wb_o         <= pc_plus_4_mem_i;
      rd_wb_o                <= rd_mem_i;
      csr_load_data_wb_o     <= csr_load_data_i;
    end
  end

endmodule
