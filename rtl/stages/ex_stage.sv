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


  logic alu_equal;
  logic alu_signed_less_than;
  logic alu_unsigned_less_than;

  logic pc_redirect_condition_met;
  logic [31:0] pc_plus_immediate;

  assign pc_plus_4_data_o  = pc_i + 32'd4;
  assign pc_plus_immediate = immediate_i + pc_i;

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
      .operand_a_i         (alu_operand_a),
      .operand_b_i         (alu_operand_b),
      .operation_i         (execute_control_i.alu_operation),
      .result_o            (alu_result_o),
      .equal_o             (alu_equal),
      .signed_less_than_o  (alu_signed_less_than),
      .unsigned_less_than_o(alu_unsigned_less_than)

  );

  always_comb begin
    case (execute_control_i.pc_redirect_condition)
      PC_REDIRECT_NEVER:  pc_redirect_condition_met = 1'b0;
      PC_REDIRECT_EQ:     pc_redirect_condition_met = alu_equal;
      PC_REDIRECT_NEQ:    pc_redirect_condition_met = !alu_equal;
      PC_REDIRECT_LT:     pc_redirect_condition_met = alu_signed_less_than;
      PC_REDIRECT_GE:     pc_redirect_condition_met = !alu_signed_less_than;
      PC_REDIRECT_ULT:    pc_redirect_condition_met = alu_unsigned_less_than;
      PC_REDIRECT_UGE:    pc_redirect_condition_met = !alu_unsigned_less_than;
      PC_REDIRECT_ALWAYS: pc_redirect_condition_met = 1'b1;
      default:            pc_redirect_condition_met = 1'b0;
    endcase
  end

  always_comb begin
    case (execute_control_i.pc_redirect_address_source)
      PC_REDIRECT_ADDRESS_PC_IMMEDIATE: pc_redirect_address_o = pc_plus_immediate;
      PC_REDIRECT_ADDRESS_ALU_RESULT:   pc_redirect_address_o = alu_result_o;
      default:                          pc_redirect_address_o = '0;
    endcase

    if (execute_control_i.pc_redirect_zero_lsb) pc_redirect_address_o[0] = 1'b0;
  end

  assign pc_redirect_enable_o = pc_redirect_condition_met && valid_i;
endmodule
