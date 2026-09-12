timeunit 1ns / 1ps;
import core_types::*;

module ex_stage (
    input logic [31:0] rs1_data_i,
    input logic [31:0] rs2_data_i,

    input execute_control_t execute_control_i,
    input memory_control_t memory_control_i,
    output memory_control_t memory_control_o,
    input writeback_control_t writeback_control_i,
    output writeback_control_t writeback_control_o,

    input logic [31:0] immediate_i,
    input logic valid_i,
    input logic [31:0] pc_i,
    input logic [4:0] rs1_i,
    input logic [4:0] rs2_i,
    input logic [4:0] rd_i,

    output logic valid_o,
    output logic [31:0] pc_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [4:0] rd_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] alu_result_o

);

  assign memory_control_o = memory_control_i;
  assign writeback_control_o = writeback_control_i;

  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;

  assign valid_o    = valid_i;
  assign pc_o       = pc_i;
  assign rs1_o      = rs1_i;
  assign rs2_o      = rs2_i;
  assign rd_o       = rd_i;
  assign rs2_data_o = rs2_data_i;

  always_comb begin
    case (execute_control_i.alu_operand_a_select)
      ALU_OPERAND_A_RS1: alu_operand_a = rs1_data_i;
      ALU_OPERAND_A_ZERO: alu_operand_a = '0;
      ALU_OPERAND_A_PC: alu_operand_a = pc_i;
      default: alu_operand_a = '0;
    endcase

    case (execute_control_i.alu_operand_b_select)
      ALU_OPERAND_B_RS2:    alu_operand_b = rs2_data_i;
      ALU_OPERAND_B_IMM:    alu_operand_b = immediate_i;
      default: alu_operand_b = '0;
    endcase
  end

  alu alu (
      .operand_a_i(alu_operand_a),
      .operand_b_i(alu_operand_b),
      .operation_i(execute_control_i.alu_operation),
      .result_o   (alu_result_o)
  );

endmodule
