import csr_types::*;
import core_types::*;

module trap_control_unit (
    input logic valid_mem_i,
    input logic illegal_instruction_mem_i,
    input system_operation_t system_operation_mem_i,
    input logic csr_access_illegal_i,
    input logic [31:0] fault_pc_i,
    input logic [31:0] fault_instruction_i,

    output logic trap_taken_o,
    output logic mret_taken_o,
    output trap_type_t trap_type_o,
    output trap_cause_exception_t trap_cause_exception_o,
    output logic flush_if_id_reg_o,
    output logic flush_id_ex_reg_o,
    output logic flush_ex_mem_reg_o,
    output logic flush_mem_wb_reg_o,
    output logic pc_redirect_enable_trap_o
);

  logic illegal_instruction_pending;
  logic ecall_pending;
  logic ebreak_pending;
  logic trap_pending;
  logic mret_pending;

  assign illegal_instruction_pending =
      valid_mem_i && (illegal_instruction_mem_i || csr_access_illegal_i);
  assign ecall_pending = valid_mem_i && system_operation_mem_i == SYSTEM_OPERATION_ECALL;
  assign ebreak_pending = valid_mem_i && system_operation_mem_i == SYSTEM_OPERATION_EBREAK;
  assign mret_pending = valid_mem_i && system_operation_mem_i == SYSTEM_OPERATION_MRET;
  assign trap_pending = illegal_instruction_pending || ecall_pending || ebreak_pending;

  assign pc_redirect_enable_trap_o = trap_taken_o || mret_taken_o;

  always_comb begin
    trap_taken_o           = 1'b0;
    mret_taken_o           = 1'b0;
    trap_type_o            = TRAP_TYPE_EXCEPTION;
    trap_cause_exception_o = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    flush_if_id_reg_o      = 1'b0;
    flush_id_ex_reg_o      = 1'b0;
    flush_ex_mem_reg_o     = 1'b0;
    flush_mem_wb_reg_o     = 1'b0;

    if (trap_pending) begin
      trap_taken_o = 1'b1;
      trap_type_o  = TRAP_TYPE_EXCEPTION;
      if (ecall_pending) trap_cause_exception_o = TRAP_CAUSE_MACHINE_ECALL;
      else if (ebreak_pending) trap_cause_exception_o = TRAP_CAUSE_BREAKPOINT;
      else trap_cause_exception_o = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
      flush_if_id_reg_o  = 1'b1;
      flush_id_ex_reg_o  = 1'b1;
      flush_ex_mem_reg_o = 1'b1;
      flush_mem_wb_reg_o = 1'b1;
    end else if (mret_pending) begin
      mret_taken_o       = 1'b1;
      flush_if_id_reg_o  = 1'b1;
      flush_id_ex_reg_o  = 1'b1;
      flush_ex_mem_reg_o = 1'b1;
    end
  end
endmodule
