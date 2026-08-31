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

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [ 4:0] rd
);
  opcode_t opcode;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [6:0] funct7;
  instr_type_t instr_type;
  alu_op_t alu_op;
  logic [31:0] imm;

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
      .read_data_1 (rs1_data),
      .read_data_2 (rs2_data)
  );
endmodule
