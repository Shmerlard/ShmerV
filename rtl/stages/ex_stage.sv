timeunit 1ns / 1ps;
import core_types::*;

module ex_stage (
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic [1:0] alu_src_a_sel,
    input logic alu_src_b_sel,
    input alu_op_t alu_op,
    input logic valid_ex_in,
    input logic [31:0] pc_in,
    input logic [4:0] rs1_reg_in,
    input logic [4:0] rs2_reg_in,
    input logic [4:0] rd_reg_in,

    output logic valid_ex_out,
    output logic [31:0] pc_out,
    output logic [4:0] rs1_reg_out,
    output logic [4:0] rs2_reg_out,
    output logic [4:0] rd_reg_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] alu_output

);
  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;

  assign valid_ex_out = valid_ex_in;
  assign pc_out       = pc_in;
  assign rs1_reg_out  = rs1_reg_in;
  assign rs2_reg_out  = rs2_reg_in;
  assign rd_reg_out   = rd_reg_in;
  assign rs2_data_out = rs2_data;

  always_comb begin
    case (alu_src_a_sel)
      2'b00:   alu_operand_a = rs1_data;
      2'b01:   alu_operand_a = '0;
      2'b10:   alu_operand_a = pc_in;
      default: alu_operand_a = '0;
    endcase

    case (alu_src_b_sel)
      1'b0:    alu_operand_b = rs2_data;
      1'b1:    alu_operand_b = imm;
      default: alu_operand_b = '0;
    endcase
  end

  alu alu (
      .a     (alu_operand_a),
      .b     (alu_operand_b),
      .op    (alu_op),
      .result(alu_output)
  );

endmodule
