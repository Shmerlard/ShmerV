timeunit 1ns / 1ps;
import core_types::*;
import csr_types::*;

module trap_control_unit_tb;
  logic valid_mem_i, illegal_instruction_mem_i, csr_access_illegal_i;
  system_operation_t system_operation_mem_i;
  memory_alignment_exception_t memory_alignment_exception_i;
  logic ext_irq_i, interrupts_enabled_i;
  irq_address_t ext_irq_address_i;
  logic trap_taken_o, mret_taken_o;
  trap_type_t trap_type_o;
  logic [4:0] trap_cause_o;
  logic flush_if_id_reg_o, flush_id_ex_reg_o, flush_ex_mem_reg_o, flush_mem_wb_reg_o;
  logic pc_redirect_enable_trap_o;

  trap_control_unit dut (.*);

  task automatic check_idle;
    #1ns;
    assert (!trap_taken_o && !mret_taken_o && !pc_redirect_enable_trap_o);
    assert (!(flush_if_id_reg_o || flush_id_ex_reg_o || flush_ex_mem_reg_o || flush_mem_wb_reg_o));
  endtask

  task automatic check_trap(input trap_type_t kind, input logic [4:0] cause);
    #1ns;
    assert (trap_taken_o && !mret_taken_o && pc_redirect_enable_trap_o);
    assert (trap_type_o == kind && trap_cause_o == cause);
    assert (flush_if_id_reg_o && flush_id_ex_reg_o && flush_ex_mem_reg_o && flush_mem_wb_reg_o);
  endtask

  initial begin
    valid_mem_i = 1'b1;
    illegal_instruction_mem_i = 1'b0;
    csr_access_illegal_i = 1'b0;
    memory_alignment_exception_i = MEMORY_ALIGNMENT_NONE;
    system_operation_mem_i = SYSTEM_OPERATION_NONE;
    ext_irq_i = 1'b0;
    interrupts_enabled_i = 1'b1;
    ext_irq_address_i = IRQ_ADDRESS_UART_RX;
    check_idle();
    ext_irq_i = 1'b1;
    interrupts_enabled_i = 1'b0;
    check_idle();
    interrupts_enabled_i = 1'b1;
    valid_mem_i = 1'b0;
    check_idle();
    valid_mem_i = 1'b1;
    for (int source = 0; source < 4; source++) begin
      ext_irq_address_i = irq_address_t'(source);
      check_trap(TRAP_TYPE_INTERRUPT, 5'(16 + source));
    end

    // Synchronous exceptions and MRET win over a simultaneous enabled IRQ.
    illegal_instruction_mem_i = 1'b1;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_ILLEGAL_INSTRUCTION);
    illegal_instruction_mem_i = 1'b0;
    csr_access_illegal_i = 1'b1;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_ILLEGAL_INSTRUCTION);
    csr_access_illegal_i = 1'b0;
    // Alignment exceptions win over enabled IRQs, but invalid entries cannot trap.
    memory_alignment_exception_i = MEMORY_ALIGNMENT_LOAD_MISALIGNED;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_LOAD_ADDRESS_MISALIGNED);
    valid_mem_i = 1'b0;
    check_idle();
    valid_mem_i = 1'b1;
    memory_alignment_exception_i = MEMORY_ALIGNMENT_STORE_MISALIGNED;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_STORE_ADDRESS_MISALIGNED);
    valid_mem_i = 1'b0;
    check_idle();
    valid_mem_i = 1'b1;
    memory_alignment_exception_i = MEMORY_ALIGNMENT_NONE;
    system_operation_mem_i = SYSTEM_OPERATION_ECALL;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_MACHINE_ECALL);
    system_operation_mem_i = SYSTEM_OPERATION_EBREAK;
    check_trap(TRAP_TYPE_EXCEPTION, TRAP_CAUSE_BREAKPOINT);
    system_operation_mem_i = SYSTEM_OPERATION_MRET;
    #1ns;
    assert (!trap_taken_o && mret_taken_o && pc_redirect_enable_trap_o);
    assert (flush_if_id_reg_o && flush_id_ex_reg_o && flush_ex_mem_reg_o && !flush_mem_wb_reg_o);
    valid_mem_i = 1'b0;
    check_idle();
    $display("trap control tests passed");
    $finish;
  end
endmodule
