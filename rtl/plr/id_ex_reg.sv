import core_types::*;

module id_ex_reg (
    input logic clk,
    input logic rst,

    input logic valid_id_i,
    input execute_control_t execute_control_id_i,
    input memory_control_t memory_control_id_i,
    input writeback_control_t writeback_control_id_i,
    input logic [31:0] rs1_data_id_i,
    input logic [31:0] rs2_data_id_i,
    input logic [31:0] immediate_id_i,
    input logic [31:0] pc_id_i,
    input logic [4:0] rd_id_i,
    input logic [4:0] rs1_id_i,
    input logic [4:0] rs2_id_i,
    input logic [31:0] instruction_id_i,
    input logic illegal_instruction_id_i,
    input logic [11:0] csr_address_id_i,
    input logic flush_id_ex_i,

    output execute_control_t execute_control_ex_o,
    output logic valid_ex_o,
    output memory_control_t memory_control_ex_o,
    output writeback_control_t writeback_control_ex_o,
    output logic [31:0] rs1_data_ex_o,
    output logic [31:0] rs2_data_ex_o,
    output logic [31:0] immediate_ex_o,
    output logic [31:0] pc_ex_o,
    output logic [4:0] rd_ex_o,
    output logic [4:0] rs1_ex_o,
    output logic [4:0] rs2_ex_o,
    output logic [31:0] instruction_ex_o,
    output logic illegal_instruction_ex_o,
    output logic [11:0] csr_address_ex_o

);

  always_ff @(posedge clk) begin
    if (rst) begin
      valid_ex_o               <= 1'b0;
      execute_control_ex_o     <= '0;
      memory_control_ex_o      <= '0;
      writeback_control_ex_o   <= '0;
      rs1_data_ex_o            <= '0;
      rs2_data_ex_o            <= '0;
      immediate_ex_o           <= '0;
      pc_ex_o                  <= '0;
      rd_ex_o                  <= '0;
      rs1_ex_o                 <= '0;
      rs2_ex_o                 <= '0;
      instruction_ex_o         <= '0;
      illegal_instruction_ex_o <= 1'b0;
      csr_address_ex_o         <= '0;
    end else if (flush_id_ex_i) begin
      valid_ex_o               <= 1'b0;
      illegal_instruction_ex_o <= 1'b0;
    end else begin
      valid_ex_o               <= valid_id_i;
      execute_control_ex_o     <= execute_control_id_i;
      memory_control_ex_o      <= memory_control_id_i;
      writeback_control_ex_o   <= writeback_control_id_i;
      rs1_data_ex_o            <= rs1_data_id_i;
      rs2_data_ex_o            <= rs2_data_id_i;
      immediate_ex_o           <= immediate_id_i;
      pc_ex_o                  <= pc_id_i;
      rd_ex_o                  <= rd_id_i;
      rs1_ex_o                 <= rs1_id_i;
      rs2_ex_o                 <= rs2_id_i;
      instruction_ex_o         <= instruction_id_i;
      illegal_instruction_ex_o <= illegal_instruction_id_i;
      csr_address_ex_o         <= csr_address_id_i;
    end
  end

endmodule
