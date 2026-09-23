timeunit 1ns; timeprecision 1ps;
import core_types::*;
import csr_types::*;

module cpu #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input logic clk,
    input logic rst,

    input logic [31:0] imem_load_data_i,
    input logic [31:0] dmem_load_data_i,
    output logic [31:0] dmem_store_data_o,
    output logic dmem_write_enable_o,
    output logic [3:0] dmem_write_byte_enable_o,
    output logic dmem_read_enable_o,
    output logic imem_read_enable_o,
    output logic [31:0] imem_read_address_o,
    output logic [31:0] dmem_address_o

);

  // fetch signals
  logic [31:0] instruction_if;
  logic [31:0] pc_if;
  logic [31:0] instruction_id;
  logic [31:0] pc_id;
  logic halt_pc;
  logic stall_if_id;

  // decode signals
  logic [31:0] rs1_data_id;
  logic [31:0] rs2_data_id;
  logic valid_id;
  logic [4:0] rd_id;
  logic [4:0] rs1_id;
  logic [4:0] rs2_id;
  logic uses_rs1_id;
  logic uses_rs2_id;
  logic bubble_id_ex;
  logic flush_id_ex_reg;
  logic [11:0] csr_address_id;
  logic instruction_invalid_id;

  execute_control_t execute_control_id;
  memory_control_t memory_control_id;
  writeback_control_t writeback_control_id;

  logic [31:0] imm_id;

  // execute signals
  execute_control_t execute_control_ex;
  memory_control_t memory_control_ex;
  writeback_control_t writeback_control_ex;

  logic [31:0] rs1_data_ex;
  logic [31:0] rs2_data_ex;
  logic [31:0] store_data_ex;
  logic [31:0] imm_ex;
  logic [31:0] pc_ex;
  logic [4:0] rd_ex;
  logic [4:0] rs1_ex;
  logic [4:0] rs2_ex;
  logic [31:0] instruction_ex;
  logic [31:0] alu_result_ex;
  logic valid_ex;

  logic pc_redirect_enable_ex;
  logic [31:0] pc_redirect_address_ex;
  logic [31:0] pc_plus_4_ex;

  forwarding_source_t rs1_forwarding_source_ex;
  forwarding_source_t rs2_forwarding_source_ex;
  logic [11:0] csr_address_ex;


  // memory signals
  memory_control_t memory_control_mem;
  writeback_control_t writeback_control_mem;
  logic [31:0] alu_result_mem;
  logic [31:0] store_data_in_mem;
  logic [31:0] forward_data_mem;

  logic [4:0] rd_mem;
  logic [31:0] dmem_address_mem;
  logic valid_mem;
  logic [31:0] pc_plus_4_mem;

  logic [31:0] dmemory_load_data_out_mem;
  // logic [31:0] csr_store_data;
  // logic [31:0] csr_load_data;
  logic [31:0] csr_load_data_out_mem;

  logic [11:0] csr_address_mem;
  // writeback signals
  writeback_control_t writeback_control_wb;
  logic [31:0] alu_result_wb;
  logic [31:0] memory_load_data_wb;
  logic [31:0] csr_load_data_wb;
  logic [4:0] rd_wb;
  logic valid_wb;
  logic [31:0] rf_write_data_wb;
  logic rf_write_enable_wb;
  logic [31:0] pc_plus_4_wb;

  // csr signals
  logic trap_taken;
  trap_type_t trap_type;
  trap_cause_exception_t trap_cause_exception;
  logic [11:0] csr_address_to_csr;
  logic [31:0] csr_load_data_mem;
  logic [31:0] csr_store_data_mem;
  logic csr_read_enable;
  logic csr_write_enable;

  assign trap_taken = 1'b0;
  assign trap_type = TRAP_TYPE_EXCEPTION;
  assign trap_cause_exception = trap_cause_exception_t'(0);

  assign dmem_address_o = dmem_address_mem;
  assign imem_read_enable_o = !halt_pc;

  if_stage #(
      .RESET_PC(RESET_PC)
  ) if_stage (
      .clk                (clk),
      .rst                (rst),
      .pc_write_enable_i  (imem_read_enable_o),
      .imem_read_data_i   (imem_load_data_i),
      .imem_read_address_o(imem_read_address_o),
      .instruction_o      (instruction_if),
      .pc_o               (pc_if),

      .pc_redirect_enable_i (pc_redirect_enable_ex),
      .pc_redirect_address_i(pc_redirect_address_ex)
  );

  if_id_reg if_id_reg (
      .clk                           (clk),
      .rst                           (rst),
      .instruction_memory_read_data_i(instruction_if),
      .pc_if_i                       (pc_if),
      .flush_id_i                    (pc_redirect_enable_ex),
      .stall_if_id_i                 (stall_if_id),
      .valid_id_o                    (valid_id),
      .instruction_id_o              (instruction_id),
      .pc_id_o                       (pc_id)
  );

  id_stage id_stage (
      .clk                     (clk),
      // .valid_i                 (valid_id),
      .instruction_id_i        (instruction_id),
      .writeback_data_i        (rf_write_data_wb),
      .writeback_rd_i          (rd_wb),
      .writeback_write_enable_i(rf_write_enable_wb),
      .rs1_data_o              (rs1_data_id),
      .rs2_data_o              (rs2_data_id),
      .immediate_o             (imm_id),
      .rd_o                    (rd_id),
      .rs1_o                   (rs1_id),
      .rs2_o                   (rs2_id),
      .csr_address_o           (csr_address_id),
      .uses_rs1_o              (uses_rs1_id),
      .uses_rs2_o              (uses_rs2_id),
      .execute_control_o       (execute_control_id),
      .memory_control_o        (memory_control_id),
      .writeback_control_o     (writeback_control_id),
      .instruction_invalid_o   (instruction_invalid_id)
  );

  assign flush_id_ex_reg = pc_redirect_enable_ex || bubble_id_ex;
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
      .rs1_id_i              (rs1_id),
      .rs2_id_i              (rs2_id),
      .instruction_id_i      (instruction_id),
      .csr_address_id_i      (csr_address_id),
      .flush_ex_i            (flush_id_ex_reg),
      .execute_control_ex_o  (execute_control_ex),
      .valid_ex_o            (valid_ex),
      .memory_control_ex_o   (memory_control_ex),
      .writeback_control_ex_o(writeback_control_ex),
      .rs1_data_ex_o         (rs1_data_ex),
      .rs2_data_ex_o         (rs2_data_ex),
      .immediate_ex_o        (imm_ex),
      .pc_ex_o               (pc_ex),
      .rd_ex_o               (rd_ex),
      .rs1_ex_o              (rs1_ex),
      .rs2_ex_o              (rs2_ex),
      .instruction_ex_o      (instruction_ex),
      .csr_address_ex_o      (csr_address_ex)
  );

  ex_stage ex_stage (
      .valid_i                (valid_ex),
      .rs1_data_i             (rs1_data_ex),
      .rs2_data_i             (rs2_data_ex),
      .execute_control_i      (execute_control_ex),
      .immediate_i            (imm_ex),
      .pc_i                   (pc_ex),
      .forward_data_mem_i     (forward_data_mem),
      .forward_data_wb_i      (rf_write_data_wb),
      .rs1_forwarding_source_i(rs1_forwarding_source_ex),
      .rs2_forwarding_source_i(rs2_forwarding_source_ex),
      .alu_result_o           (alu_result_ex),
      .pc_plus_4_data_o       (pc_plus_4_ex),
      .store_data_o           (store_data_ex),
      .pc_redirect_enable_o   (pc_redirect_enable_ex),
      .pc_redirect_address_o  (pc_redirect_address_ex)
  );

  ex_mem_reg ex_mem_reg (
      .clk                    (clk),
      .rst                    (rst),
      .valid_ex_i             (valid_ex),
      .memory_control_ex_i    (memory_control_ex),
      .writeback_control_ex_i (writeback_control_ex),
      .alu_result_ex_i        (alu_result_ex),
      .pc_plus_4_ex_i         (pc_plus_4_ex),
      .store_data_ex_i        (store_data_ex),
      .rd_ex_i                (rd_ex),
      .csr_address_ex_i       (csr_address_ex),
      .memory_control_mem_o   (memory_control_mem),
      .valid_mem_o            (valid_mem),
      .writeback_control_mem_o(writeback_control_mem),
      .alu_result_mem_o       (alu_result_mem),
      .pc_plus_4_mem_o        (pc_plus_4_mem),
      .store_data_mem_o       (store_data_in_mem),
      .rd_mem_o               (rd_mem),
      .csr_address_mem_o      (csr_address_mem)
  );

  mem_stage mem_stage (
      .valid_i            (valid_mem),
      .memory_control_i   (memory_control_mem),
      .writeback_control_i(writeback_control_mem),
      .alu_result_i       (alu_result_mem),
      .pc_plus_4_i        (pc_plus_4_mem),
      .store_data_in_mem_i(store_data_in_mem),

      .memory_address_o          (dmem_address_mem),
      .memory_write_byte_enable_o(dmem_write_byte_enable_o),
      .memory_read_enable_o      (dmem_read_enable_o),
      .memory_write_enable_o     (dmem_write_enable_o),
      .memory_store_data_o       (dmem_store_data_o),
      .memory_load_data_i        (dmem_load_data_i),
      .memory_load_data_out_mem_o(dmemory_load_data_out_mem),

      .csr_read_enable_o      (csr_read_enable),
      .csr_write_enable_o     (csr_write_enable),
      .csr_address_i          (csr_address_mem),
      .csr_address_o          (csr_address_to_csr),
      .csr_store_data_o       (csr_store_data_mem),
      .csr_load_data_i        (csr_load_data_mem),
      .csr_load_data_out_mem_o(csr_load_data_out_mem),

      .forward_data_o(forward_data_mem)
  );

  mem_wb_reg mem_wb_reg (
      .clk                    (clk),
      .rst                    (rst),
      .valid_mem_i            (valid_mem),
      .writeback_control_mem_i(writeback_control_mem),
      .alu_result_mem_i       (alu_result_mem),
      .pc_plus_4_mem_i        (pc_plus_4_mem),
      .dmemory_load_data_mem_i(dmemory_load_data_out_mem),
      .rd_mem_i               (rd_mem),
      .csr_load_data_i        (csr_load_data_out_mem),
      .writeback_control_wb_o (writeback_control_wb),
      .valid_wb_o             (valid_wb),
      .alu_result_wb_o        (alu_result_wb),
      .pc_plus_4_wb_o         (pc_plus_4_wb),
      .dmemory_load_data_wb_o (memory_load_data_wb),
      .rd_wb_o                (rd_wb),
      .csr_load_data_wb_o     (csr_load_data_wb)
  );

  wb_stage wb_stage (
      .valid_i            (valid_wb),
      .writeback_control_i(writeback_control_wb),
      .alu_result_i       (alu_result_wb),
      .memory_load_data_i (memory_load_data_wb),
      .csr_load_data_i    (csr_load_data_wb),
      .pc_plus_4_i        (pc_plus_4_wb),
      .writeback_data_o   (rf_write_data_wb),
      .rf_write_enable_o  (rf_write_enable_wb)
  );

  hazard_unit hazard_unit (
      .rs1_ex_i(rs1_ex),
      .rs2_ex_i(rs2_ex),
      .rs1_id_i(rs1_id),
      .rs2_id_i(rs2_id),
      .uses_rs1_id_i(uses_rs1_id),
      .uses_rs2_id_i(uses_rs2_id),
      .valid_id_i(valid_id),
      .valid_ex_i(valid_ex),
      .rd_ex_i(rd_ex),
      .memory_read_ex_i       (memory_control_ex.read_enable &&
                               memory_control_ex.target == MEMORY_TARGET_DMEMORY),
      .rd_mem_i(rd_mem),
      .rd_wb_i(rd_wb),
      .valid_mem_i(valid_mem),
      .valid_wb_i(valid_wb),
      .reg_write_mem_i(writeback_control_mem.register_write_enable),
      .reg_write_wb_i(writeback_control_wb.register_write_enable),
      .writeback_source_mem_i(writeback_control_mem.writeback_source),
      .halt_pc_o(halt_pc),
      .stall_if_id_o(stall_if_id),
      .bubble_id_ex_o(bubble_id_ex),
      .rs1_forwarding_source_o(rs1_forwarding_source_ex),
      .rs2_forwarding_source_o(rs2_forwarding_source_ex)
  );

  csr csr (
      .clk                   (clk),
      .rst                   (rst),
      .csr_read_enable_i     (csr_read_enable),
      .csr_write_enable_i    (csr_write_enable),
      .trap_taken_i          (trap_taken),
      .trap_pc_ex_i          (pc_ex),
      .trap_type_i           (trap_type),
      .trap_cause_exception_i(trap_cause_exception),
      .trap_instruction_ex_i (instruction_ex),
      .csr_address_i         (csr_address_to_csr),
      .csr_write_data_i      (csr_store_data_mem),
      .csr_load_data_o       (csr_load_data_mem)
  );

endmodule
