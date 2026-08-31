timeunit 1ns / 1ps;
import core_types::*;

module id_stage (
    input logic clk,
    input logic valid_id,
    input logic [31:0] instr_id,
    input logic [31:0] pc_id,
    input logic [31:0] wb_wr_data,
    input logic [4:0] wb_wr_reg,
    input logic wb_wr_en,
    input logic [1:0] alu_src_a_sel,
    input logic alu_src_b_sel,

    output logic [31:0] alu_operand_a,
    output logic [31:0] alu_operand_b,
    output logic [4:0] rd,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output alu_op_t alu_op,
    output logic [31:0] pc_id_out,
    output logic valid_id_out

);
  opcode_t opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  instr_type_t instr_type;
  logic [31:0] imm;
  logic [31:0] rs1_data_rf;
  logic [31:0] rs2_data_rf;

  assign pc_id_out    = pc_id;
  assign valid_id_out = valid_id;

  instruction_decoder id (
      .instr     (instr_id),
      .opcode    (opcode),
      .rd        (rd),
      .funct3    (funct3),
      .rs1       (rs1),
      .rs2       (rs2),
      .funct7    (funct7),
      .instr_type(instr_type),
      .alu_op    (alu_op)
  );

  immediate_generator immediate_generator (
      .instr     (instr_id),
      .instr_type(instr_type),
      .imm       (imm)
  );
  register_file register_file (
      .clk         (clk),
      .read_addr_1 (rs1),
      .read_addr_2 (rs2),
      .write_enable(wb_wr_en),
      .write_addr  (wb_wr_reg),
      .write_data  (wb_wr_data),
      .read_data_1 (rs1_data_rf),
      .read_data_2 (rs2_data_rf)
  );


  always_comb begin
    case (alu_src_a_sel)
      2'b00:   alu_operand_a = rs1_data_rf;
      2'b01:   alu_operand_a = '0;
      2'b10:   alu_operand_a = pc_id;
      default: alu_operand_a = '0;
    endcase
    // TODO: add enums

    case (alu_src_b_sel)
      '0: alu_operand_b = rs2_data_rf;
      '1: alu_operand_b = imm;
      default: alu_operand_b = '0;
    endcase
  end
endmodule
