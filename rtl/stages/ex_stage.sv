timeunit 1ns / 1ps;
import core_types::*;

module ex_stage (
    input logic [31:0] rs1_data_i,
    input logic [31:0] rs2_data_i,
    input logic [31:0] immediate_i,
    input logic [1:0] alu_operand_a_select_i,
    input logic alu_operand_b_select_i,
    input alu_operation_t alu_operation_i,
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
  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;

  assign valid_o    = valid_i;
  assign pc_o       = pc_i;
  assign rs1_o      = rs1_i;
  assign rs2_o      = rs2_i;
  assign rd_o       = rd_i;
  assign rs2_data_o = rs2_data_i;

  always_comb begin
    case (alu_operand_a_select_i)
      2'b00:   alu_operand_a = rs1_data_i;
      2'b01:   alu_operand_a = '0;
      2'b10:   alu_operand_a = pc_i;
      default: alu_operand_a = '0;
    endcase

    case (alu_operand_b_select_i)
      1'b0:    alu_operand_b = rs2_data_i;
      1'b1:    alu_operand_b = immediate_i;
      default: alu_operand_b = '0;
    endcase
  end

  alu alu (
      .operand_a_i(alu_operand_a),
      .operand_b_i(alu_operand_b),
      .operation_i(alu_operation_i),
      .result_o   (alu_result_o)
  );

endmodule
