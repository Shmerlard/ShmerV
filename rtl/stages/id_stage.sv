timeunit 1ns / 1ps;
import core_types::*;

module id_stage (
    input logic clk,
    input logic valid_i,
    input logic [31:0] instruction_id_i,
    input logic [31:0] writeback_data_i,
    input logic [4:0] writeback_rd_i,
    input logic writeback_write_enable_i,

    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] immediate_o,
    output logic [4:0] rd_o,
    output execute_control_t execute_control_o,
    output memory_control_t memory_control_o,
    output writeback_control_t writeback_control_o

);
  opcode_t opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1;
  logic [4:0] rs2;
  instruction_type_t instr_type;
  instruction_decoder id (
      .instruction_i     (instruction_id_i),
      .opcode_o          (opcode),
      .rd_o              (rd_o),
      .funct3_o          (funct3),
      .rs1_o             (rs1),
      .rs2_o             (rs2),
      .funct7_o          (funct7),
      .instruction_type_o(instr_type)
  );

  controller controller (
      .opcode_i           (opcode),
      .funct3_i           (funct3),
      .funct7_i           (funct7),
      .execute_control_o  (execute_control_o),
      .memory_control_o   (memory_control_o),
      .writeback_control_o(writeback_control_o)
  );

  immediate_generator immediate_generator (
      .instruction_i     (instruction_id_i),
      .instruction_type_i(instr_type),
      .immediate_o       (immediate_o)
  );
  register_file register_file (
      .clk             (clk),
      .read_address_1_i(rs1),
      .read_address_2_i(rs2),
      .write_enable_i  (writeback_write_enable_i),
      .write_address_i (writeback_rd_i),
      .write_data_i    (writeback_data_i),
      .read_data_1_o   (rs1_data_o),
      .read_data_2_o   (rs2_data_o)
  );
endmodule
