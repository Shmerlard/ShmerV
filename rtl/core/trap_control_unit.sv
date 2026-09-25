import csr_types::*;

module trap_control_unit (
    input logic valid_mem_i,
    input logic illegal_instruction_mem_i,
    input logic csr_access_illegal_i,
    input logic [31:0] fault_pc_i,
    input logic [31:0] fault_instruction_i,

    output logic trap_taken_o,
    output trap_type_t trap_type_o,
    output trap_cause_exception_t trap_cause_exception_o,
    output logic flush_if_id_reg_o,
    output logic flush_id_ex_reg_o,
    output logic flush_ex_mem_reg_o,
    output logic flush_mem_wb_reg_o,
    output logic pc_redirect_enable_trap_o
);

  logic trap_pending;

  assign trap_pending = valid_mem_i && (illegal_instruction_mem_i || csr_access_illegal_i);

  assign pc_redirect_enable_trap_o = trap_taken_o;

  always_comb begin
    trap_taken_o           = 1'b0;
    trap_type_o            = TRAP_TYPE_EXCEPTION;
    trap_cause_exception_o = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    flush_if_id_reg_o      = 1'b0;
    flush_id_ex_reg_o      = 1'b0;
    flush_ex_mem_reg_o     = 1'b0;
    flush_mem_wb_reg_o     = 1'b0;

    if (trap_pending) begin
      trap_taken_o           = 1'b1;
      trap_type_o            = TRAP_TYPE_EXCEPTION;
      trap_cause_exception_o = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
      flush_if_id_reg_o      = 1'b1;
      flush_id_ex_reg_o      = 1'b1;
      flush_ex_mem_reg_o     = 1'b1;
      flush_mem_wb_reg_o     = 1'b1;
    end
  end
endmodule
