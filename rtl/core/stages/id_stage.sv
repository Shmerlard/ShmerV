timeunit 1ns / 1ps;
import core_types::*;

module id_stage (
    input logic clk,
    // input logic valid_i,
    input logic [31:0] instruction_id_i,
    input logic [31:0] writeback_data_i,
    input logic [4:0] writeback_rd_i,
    input logic writeback_write_enable_i,

    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] immediate_o,
    output logic [4:0] rd_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [11:0] csr_address_o,  // TODO: maybe better name so it wont be linked to csr only
    output logic uses_rs1_o,
    output logic uses_rs2_o,
    output execute_control_t execute_control_o,
    output memory_control_t memory_control_o,
    output writeback_control_t writeback_control_o,
    output system_operation_t system_operation_o,
    output illegal_instruction_o

);
  opcode_t opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [11:0] funct12;
  logic [31:0] register_file_rs1_data;
  logic [31:0] register_file_rs2_data;
  logic rs1_wb_bypass_enable;
  logic rs2_wb_bypass_enable;
  instruction_type_t instr_type;

  assign rs1_wb_bypass_enable =
      writeback_write_enable_i && (writeback_rd_i != 5'b0) && (writeback_rd_i == rs1_o);
  assign rs2_wb_bypass_enable =
      writeback_write_enable_i && (writeback_rd_i != 5'b0) && (writeback_rd_i == rs2_o);

  assign rs1_data_o = rs1_wb_bypass_enable ? writeback_data_i : register_file_rs1_data;
  assign rs2_data_o = rs2_wb_bypass_enable ? writeback_data_i : register_file_rs2_data;

  assign funct12 = instruction_id_i[31:20];
  assign csr_address_o = funct12;

  instruction_decoder id (
      .instruction_i     (instruction_id_i),
      .opcode_o          (opcode),
      .rd_o              (rd_o),
      .funct3_o          (funct3),
      .rs1_o             (rs1_o),
      .rs2_o             (rs2_o),
      .funct7_o          (funct7),
      .instruction_type_o(instr_type)
  );

  controller controller (
      .opcode_i             (opcode),
      .funct3_i             (funct3),
      .funct7_i             (funct7),
      .funct12_i            (funct12),
      .rs1_i                (rs1_o),
      .rd_i                 (rd_o),
      .execute_control_o    (execute_control_o),
      .memory_control_o     (memory_control_o),
      .writeback_control_o  (writeback_control_o),
      .system_operation_o   (system_operation_o),
      .uses_rs1_o           (uses_rs1_o),
      .uses_rs2_o           (uses_rs2_o),
      .illegal_instruction_o(illegal_instruction_o)
  );

  immediate_generator immediate_generator (
      .instruction_i     (instruction_id_i),
      .instruction_type_i(instr_type),
      .immediate_o       (immediate_o)
  );
  register_file register_file (
      .clk             (clk),
      .read_address_1_i(rs1_o),
      .read_address_2_i(rs2_o),
      .write_enable_i  (writeback_write_enable_i),
      .write_address_i (writeback_rd_i),
      .write_data_i    (writeback_data_i),
      .read_data_1_o   (register_file_rs1_data),
      .read_data_2_o   (register_file_rs2_data)
  );
endmodule
