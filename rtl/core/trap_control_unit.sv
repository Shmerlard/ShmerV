import csr_types::*;
import core_types::*;

module trap_control_unit (
    input logic valid_mem_i,
    input logic illegal_instruction_mem_i,
    input system_operation_t system_operation_mem_i,
    input logic csr_access_illegal_i,
    input memory_alignment_exception_t memory_alignment_exception_i,

    input logic ext_irq_i,
    input irq_address_t ext_irq_address_i,
    input logic interrupts_enabled_i,

    output logic trap_taken_o,
    output logic mret_taken_o,
    output trap_type_t trap_type_o,
    output logic [4:0] trap_cause_o,
    output logic flush_if_id_reg_o,
    output logic flush_id_ex_reg_o,
    output logic flush_ex_mem_reg_o,
    output logic flush_mem_wb_reg_o,
    output logic pc_redirect_enable_trap_o
);

  logic illegal_instruction_pending;
  logic load_misalignment_pending;
  logic store_misalignment_pending;
  logic ecall_pending;
  logic ebreak_pending;
  logic trap_pending;
  logic interrupt_pending;
  logic mret_pending;
  trap_cause_exception_t trap_cause_exception;
  trap_cause_interrupt_t trap_cause_interrupt;

  always_comb begin
    illegal_instruction_pending = 0;
    load_misalignment_pending = 0;
    store_misalignment_pending = 0;
    ecall_pending = 0;
    ebreak_pending = 0;
    mret_pending = 0;
    trap_pending = 0;
    interrupt_pending = 0;

    if (valid_mem_i) begin
      if (illegal_instruction_mem_i || csr_access_illegal_i) illegal_instruction_pending = 1;

      if (memory_alignment_exception_i == MEMORY_ALIGNMENT_LOAD_MISALIGNED)
        load_misalignment_pending = 1;
      else if (memory_alignment_exception_i == MEMORY_ALIGNMENT_STORE_MISALIGNED)
        store_misalignment_pending = 1;

      if (ext_irq_i && interrupts_enabled_i) interrupt_pending = 1;
      case (system_operation_mem_i)
        SYSTEM_OPERATION_ECALL:  ecall_pending = 1;
        SYSTEM_OPERATION_EBREAK: ebreak_pending = 1;
        SYSTEM_OPERATION_MRET:   mret_pending = 1;
        SYSTEM_OPERATION_NONE:   ;
      endcase
      trap_pending = store_misalignment_pending || load_misalignment_pending || illegal_instruction_pending || ecall_pending || ebreak_pending;
    end
  end

  assign pc_redirect_enable_trap_o = trap_taken_o || mret_taken_o;

  always_comb begin
    trap_taken_o         = 1'b0;
    mret_taken_o         = 1'b0;
    trap_type_o          = TRAP_TYPE_EXCEPTION;
    trap_cause_o         = 0;
    trap_cause_exception = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    trap_cause_interrupt = TRAP_CAUSE_MACHINE_EXTERNAL_INTERRUPT;
    flush_if_id_reg_o    = 1'b0;
    flush_id_ex_reg_o    = 1'b0;
    flush_ex_mem_reg_o   = 1'b0;
    flush_mem_wb_reg_o   = 1'b0;

    if (trap_pending) begin
      trap_taken_o = 1'b1;
      trap_type_o  = TRAP_TYPE_EXCEPTION;
      if (ecall_pending) trap_cause_exception = TRAP_CAUSE_MACHINE_ECALL;
      else if (ebreak_pending) trap_cause_exception = TRAP_CAUSE_BREAKPOINT;
      else if (illegal_instruction_pending) trap_cause_exception = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
      else if (load_misalignment_pending) trap_cause_exception = TRAP_CAUSE_LOAD_ADDRESS_MISALIGNED;
      else if (store_misalignment_pending)
        trap_cause_exception = TRAP_CAUSE_STORE_ADDRESS_MISALIGNED;

      trap_cause_o = trap_cause_exception;
      flush_if_id_reg_o = 1'b1;
      flush_id_ex_reg_o = 1'b1;
      flush_ex_mem_reg_o = 1'b1;
      flush_mem_wb_reg_o = 1'b1;
    end else if (mret_pending) begin
      mret_taken_o       = 1'b1;
      flush_if_id_reg_o  = 1'b1;
      flush_id_ex_reg_o  = 1'b1;
      flush_ex_mem_reg_o = 1'b1;
    end else if (interrupt_pending) begin
      case (ext_irq_address_i)
        IRQ_ADDRESS_UART_RX: trap_cause_interrupt = TRAP_CAUSE_RX;
        IRQ_ADDRESS_GPIO_A:  trap_cause_interrupt = TRAP_CAUSE_GPIO_A;
        IRQ_ADDRESS_GPIO_B:  trap_cause_interrupt = TRAP_CAUSE_GPIO_B;
        IRQ_ADDRESS_GPIO_C:  trap_cause_interrupt = TRAP_CAUSE_GPIO_C;
        default: begin
        end
      endcase
      trap_taken_o = 1'b1;
      trap_type_o = TRAP_TYPE_INTERRUPT;
      trap_cause_o = trap_cause_interrupt;
      flush_if_id_reg_o = 1'b1;
      flush_id_ex_reg_o = 1'b1;
      flush_ex_mem_reg_o = 1'b1;
      flush_mem_wb_reg_o = 1'b1;
    end
  end
endmodule
