timeunit 1ns / 1ps;
import core_types::*;

module ex_stage (
    input logic valid_i,
    input logic [31:0] rs1_data_i,
    input logic [31:0] rs2_data_i,

    input execute_control_t execute_control_i,

    input logic [31:0] immediate_i,
    input logic [31:0] pc_i,

    output logic [31:0] alu_result_o,
    output logic [31:0] pc_plus_4_data_o,

    output logic pc_redirect_enable_o,
    output logic [31:0] pc_redirect_address_o

);
  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;

  assign pc_plus_4_data_o = pc_i + 32'd4;

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

  assign pc_redirect_enable_o  = execute_control_i.pc_redirect_enable && valid_i;
  assign pc_redirect_address_o = alu_result_o;
endmodule
