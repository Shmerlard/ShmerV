import core_types::*;

module ex_mem_reg (
    input logic clk,
    input logic rst,

    input logic valid_ex_i,
    input memory_control_t memory_control_ex_i,
    input writeback_control_t writeback_control_ex_i,
    input logic [31:0] alu_result_ex_i,
    input logic [31:0] pc_plus_4_ex_i,
    input logic [31:0] forwarded_rs1_data_ex_i,
    input logic [31:0] store_data_ex_i,  //TODO: find better name
    input logic [4:0] rd_ex_i,
    input logic [11:0] csr_address_ex_i,

    output memory_control_t memory_control_mem_o,
    output logic valid_mem_o,
    output writeback_control_t writeback_control_mem_o,
    output logic [31:0] alu_result_mem_o,
    output logic [31:0] pc_plus_4_mem_o,
    output logic [31:0] store_data_mem_o,
    output logic [31:0] rs1_data_mem_o,
    output logic [4:0] rd_mem_o,
    output logic [11:0] csr_address_mem_o
);

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_mem_o             <= 1'b0;
      memory_control_mem_o    <= '0;
      writeback_control_mem_o <= '0;
      alu_result_mem_o        <= '0;
      pc_plus_4_mem_o         <= '0;
      store_data_mem_o        <= '0;
      rs1_data_mem_o          <= '0;
      rd_mem_o                <= '0;
      csr_address_mem_o       <= '0;
    end else begin
      valid_mem_o             <= valid_ex_i;
      memory_control_mem_o    <= memory_control_ex_i;
      writeback_control_mem_o <= writeback_control_ex_i;
      alu_result_mem_o        <= alu_result_ex_i;
      pc_plus_4_mem_o         <= pc_plus_4_ex_i;
      store_data_mem_o        <= store_data_ex_i;
      rs1_data_mem_o          <= forwarded_rs1_data_ex_i;
      rd_mem_o                <= rd_ex_i;
      csr_address_mem_o       <= csr_address_ex_i;
    end
  end

endmodule
