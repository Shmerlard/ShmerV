timeunit 1ns; timeprecision 1ps;
import core_types::*;

module cpu (
    input logic clk,
    input logic rst,

    input logic [31:0] imem_read_data_i,
    input logic [31:0] dmem_read_data_i,
    output logic dmem_write_enable_o,
    output logic dmem_read_enable_o,
    output logic [31:0] imem_read_address_o,
    output logic [31:0] dmem_read_address_o,
    output logic [31:0] dmem_write_address_o,
    output logic [31:0] dmem_write_data_o

);

  // fetch signals
  logic [31:0] instruction_if;
  logic [31:0] pc_if;
  assign pc_if = imem_read_address_o;
  logic [31:0] instruction_id;
  logic [31:0] pc_id;

  // decode signals
  logic [31:0] rs1_data_id;
  logic [31:0] rs2_data_id;
  logic valid_id;
  logic [4:0] rd_id;

  execute_control_t execute_control_id;
  memory_control_t memory_control_id;
  writeback_control_t writeback_control_id;

  logic [31:0] rf_write_data_wb;
  logic rf_write_enable_wb;
  logic [31:0] imm_id;

  // execute signals
  execute_control_t execute_control_ex;
  memory_control_t memory_control_ex;
  writeback_control_t writeback_control_ex;

  logic [31:0] rs1_data_ex;
  logic [31:0] rs2_data_ex;
  logic [31:0] imm_ex;
  logic [31:0] pc_ex;
  logic [4:0] rd_ex;
  logic [31:0] alu_result_ex;
  logic valid_ex;

  // memory signals
  memory_control_t memory_control_mem;
  writeback_control_t writeback_control_mem;
  logic [31:0] alu_result_mem;
  logic [31:0] rs2_data_mem;
  logic [4:0] rd_mem;
  logic [31:0] dmem_address_mem;
  logic valid_mem;

  // writeback signals
  writeback_control_t writeback_control_wb;
  logic [31:0] alu_result_wb;
  logic [31:0] memory_read_data_wb;
  logic [4:0] rd_wb;
  logic valid_wb;

  assign dmem_read_address_o  = dmem_address_mem;
  assign dmem_write_address_o = dmem_address_mem;

  if_stage if_stage (
      .clk                           (clk),
      .rst                           (rst),
      .pc_write_enable_i             (1'b1),
      .instruction_memory_read_data_i(imem_read_data_i),
      .instruction_memory_address_o  (imem_read_address_o),
      .instruction_if_o              (instruction_if)
  );

  if_id_reg if_id_reg (
      .clk                           (clk),
      .rst                           (rst),
      .instruction_memory_read_data_i(instruction_if),
      .pc_if_i                       (pc_if),
      .valid_id_o                    (valid_id),
      .instruction_id_o              (instruction_id),
      .pc_id_o                       (pc_id)
  );

  id_stage id_stage (
      .clk                     (clk),
      .valid_i                 (valid_id),
      .instruction_id_i        (instruction_id),
      .writeback_data_i        (rf_write_data_wb),
      .writeback_rd_i          (rd_wb),
      .writeback_write_enable_i(rf_write_enable_wb),
      .rs1_data_o              (rs1_data_id),
      .rs2_data_o              (rs2_data_id),
      .immediate_o             (imm_id),
      .rd_o                    (rd_id),
      .execute_control_o       (execute_control_id),
      .memory_control_o        (memory_control_id),
      .writeback_control_o     (writeback_control_id)
  );

  id_ex_reg id_ex_reg (
      .clk                   (clk),
      .rst                   (rst),
      .valid_id_i            (valid_id),
      .execute_control_id_i  (execute_control_id),
      .memory_control_id_i   (memory_control_id),
      .writeback_control_id_i(writeback_control_id),
      .rs1_data_id_i         (rs1_data_id),
      .rs2_data_id_i         (rs2_data_id),
      .immediate_id_i        (imm_id),
      .pc_id_i               (pc_id),
      .rd_id_i               (rd_id),
      .execute_control_ex_o  (execute_control_ex),
      .valid_ex_o            (valid_ex),
      .memory_control_ex_o   (memory_control_ex),
      .writeback_control_ex_o(writeback_control_ex),
      .rs1_data_ex_o         (rs1_data_ex),
      .rs2_data_ex_o         (rs2_data_ex),
      .immediate_ex_o        (imm_ex),
      .pc_ex_o               (pc_ex),
      .rd_ex_o               (rd_ex)
  );

  ex_stage ex_stage (
      .valid_i          (valid_ex),
      .rs1_data_i       (rs1_data_ex),
      .rs2_data_i       (rs2_data_ex),
      .execute_control_i(execute_control_ex),
      .immediate_i      (imm_ex),
      .pc_i             (pc_ex),
      .alu_result_o     (alu_result_ex)
  );
  ex_mem_reg ex_mem_reg (
      .clk                    (clk),
      .rst                    (rst),
      .valid_ex_i             (valid_ex),
      .memory_control_ex_i    (memory_control_ex),
      .writeback_control_ex_i (writeback_control_ex),
      .alu_result_ex_i        (alu_result_ex),
      .rs2_data_ex_i          (rs2_data_ex),
      .rd_ex_i                (rd_ex),
      .memory_control_mem_o   (memory_control_mem),
      .valid_mem_o            (valid_mem),
      .writeback_control_mem_o(writeback_control_mem),
      .alu_result_mem_o       (alu_result_mem),
      .rs2_data_mem_o         (rs2_data_mem),
      .rd_mem_o               (rd_mem)
  );

  mem_stage mem_stage (
      .valid_i              (valid_mem),
      .alu_result_i         (alu_result_mem),
      .rs2_data_i           (rs2_data_mem),
      .memory_control_i     (memory_control_mem),
      .memory_address_o     (dmem_address_mem),
      .memory_write_data_o  (dmem_write_data_o),
      .memory_read_enable_o (dmem_read_enable_o),
      .memory_write_enable_o(dmem_write_enable_o)
  );

  mem_wb_reg mem_wb_reg (
      .clk                    (clk),
      .rst                    (rst),
      .valid_mem_i            (valid_mem),
      .writeback_control_mem_i(writeback_control_mem),
      .alu_result_mem_i       (alu_result_mem),
      .memory_read_data_mem_i (dmem_read_data_i),
      .rd_mem_i               (rd_mem),
      .writeback_control_wb_o (writeback_control_wb),
      .valid_wb_o             (valid_wb),
      .alu_result_wb_o        (alu_result_wb),
      .memory_read_data_wb_o  (memory_read_data_wb),
      .rd_wb_o                (rd_wb)
  );

  wb_stage wb_stage (
      .valid_i            (valid_wb),
      .writeback_control_i(writeback_control_wb),
      .alu_result_i       (alu_result_wb),
      .memory_read_data_i (memory_read_data_wb),
      .writeback_data_o   (rf_write_data_wb),
      .rf_write_enable_o  (rf_write_enable_wb)
  );
endmodule
