timeunit 1ns / 1ps;

import core_types::*;
import csr_types::*;

module csr_tb;
  logic clk = 1'b0;
  logic rst;
  logic csr_read_enable_i;
  logic csr_write_enable_i;
  logic trap_taken_i;
  logic mret_taken_i;
  logic [31:0] trap_pc_ex_i;
  trap_type_t trap_type_i;
  logic [4:0] trap_cause_i;
  logic [31:0] trap_instruction_ex_i;
  logic [31:0] attempted_memory_address_i;
  logic [11:0] csr_address_i;
  logic [31:0] csr_write_data_i;
  logic [31:0] csr_load_data_o;
  logic csr_access_illegal_o;
  logic [31:0] csr_pc_redirect_address_o;
  logic interrupts_enabled_o;

  csr dut (.*);

  always #5ns clk = ~clk;

  initial begin
    $dumpfile("build/tests/csr/waveform.fst");
    $dumpvars(0, csr_tb);

    rst = 1'b1;
    csr_read_enable_i = 1'b0;
    csr_write_enable_i = 1'b0;
    trap_taken_i = 1'b0;
    mret_taken_i = 1'b0;
    trap_pc_ex_i = '0;
    trap_type_i = TRAP_TYPE_EXCEPTION;
    trap_cause_i = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    trap_instruction_ex_i = '0;
    attempted_memory_address_i = '0;
    csr_address_i = CSR_ADDRESS_MSTATUS;
    csr_write_data_i = '0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;

    // Reset initializes mstatus to the implemented Machine-mode value.
    csr_read_enable_i = 1'b1;
    #1ns;
    assert (csr_load_data_o == 32'h0000_1800)
    else $fatal(1, "mstatus reset value was %h", csr_load_data_o);

    // A simultaneous CSR read/write returns the old value before the edge.
    csr_address_i = CSR_ADDRESS_MTVEC;
    csr_write_data_i = 32'h0000_0100;
    csr_write_enable_i = 1'b1;
    #1ns;
    assert (csr_load_data_o == 32'h0000_0001)
    else $fatal(1, "mtvec old value was %h", csr_load_data_o);

    @(posedge clk);
    #1ns;
    csr_write_enable_i = 1'b0;
    assert (csr_load_data_o == 32'h0000_0101)
    else $fatal(1, "mtvec write produced %h", csr_load_data_o);

    // A disabled write must preserve the CSR value.
    csr_write_data_i = 32'h0000_0200;
    @(posedge clk);
    #1ns;
    assert (csr_load_data_o == 32'h0000_0101)
    else $fatal(1, "disabled write changed mtvec to %h", csr_load_data_o);

    // An unsupported CSR read is illegal and returns no CSR data.
    csr_address_i = 12'h999;
    #1ns;
    assert (csr_access_illegal_o)
    else $fatal(1, "unsupported CSR read was not marked illegal");
    assert (csr_load_data_o == 32'b0)
    else $fatal(1, "unsupported CSR read returned %h", csr_load_data_o);

    // An unsupported CSR write is illegal and must not modify implemented CSRs.
    csr_read_enable_i  = 1'b0;
    csr_write_enable_i = 1'b1;
    csr_write_data_i   = 32'hDEAD_BEEF;
    #1ns;
    assert (csr_access_illegal_o)
    else $fatal(1, "unsupported CSR write was not marked illegal");

    @(posedge clk);
    #1ns;
    csr_write_enable_i = 1'b0;
    csr_read_enable_i = 1'b1;
    csr_address_i = CSR_ADDRESS_MTVEC;
    #1ns;
    assert (!csr_access_illegal_o)
    else $fatal(1, "implemented CSR read was marked illegal");
    assert (csr_load_data_o == 32'h0000_0101)
    else $fatal(1, "unsupported write changed mtvec to %h", csr_load_data_o);

    // Enable interrupts; MPP remains Machine even when software writes zero there.
    csr_address_i = CSR_ADDRESS_MSTATUS;
    csr_write_data_i = 32'h8;
    csr_write_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    csr_write_enable_i = 1'b0;
    assert (interrupts_enabled_o && csr_load_data_o == 32'h1808);

    // Every custom interrupt uses BASE + 4*cause; trap entry wins over CSR writes.
    for (int cause = 16; cause <= 19; cause++) begin
      trap_type_i = TRAP_TYPE_INTERRUPT;
      trap_cause_i = 5'(cause);
      trap_pc_ex_i = 32'h8000_0040;
      trap_instruction_ex_i = 32'hFFFF_FFFF;
      trap_taken_i = 1'b1;
      csr_address_i = CSR_ADDRESS_MTVAL;
      csr_write_data_i = 32'hDEAD_BEEF;
      csr_write_enable_i = 1'b1;
      #1ns;
      assert (csr_pc_redirect_address_o == 32'h100 + 4 * 32'(cause));
      @(posedge clk);
      #1ns;
      trap_taken_i = 1'b0;
      csr_write_enable_i = 1'b0;
      assert (!interrupts_enabled_o);
      assert (csr_load_data_o == 0)
      else $fatal(1, "interrupt mtval must be zero");
      csr_address_i = CSR_ADDRESS_MCAUSE;
      #1ns;
      assert (csr_load_data_o == (32'h8000_0000 | 32'(cause)));
      csr_address_i = CSR_ADDRESS_MEPC;
      #1ns;
      assert (csr_load_data_o == 32'h8000_0040);
      csr_address_i = CSR_ADDRESS_MSTATUS;
      #1ns;
      assert (csr_load_data_o == 32'h1880);

      mret_taken_i = 1'b1;
      #1ns;
      assert (csr_pc_redirect_address_o == 32'h8000_0040);
      @(posedge clk);
      #1ns;
      mret_taken_i = 1'b0;
      assert (interrupts_enabled_o && csr_load_data_o == 32'h1888);
    end

    // Exceptions always use BASE, record their instruction, and clear MIE.
    trap_type_i  = TRAP_TYPE_EXCEPTION;
    trap_cause_i = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    trap_taken_i = 1'b1;
    #1ns;
    assert (csr_pc_redirect_address_o == 32'h100);
    @(posedge clk);
    #1ns;
    trap_taken_i  = 1'b0;
    csr_address_i = CSR_ADDRESS_MTVAL;
    #1ns;
    assert (csr_load_data_o == 32'hFFFF_FFFF);
    csr_address_i = CSR_ADDRESS_MCAUSE;
    #1ns;
    assert (csr_load_data_o == 2);

    // Alignment exceptions record the complete fault address, not instruction bits.
    for (int store = 0; store < 2; store++) begin
      trap_cause_i = store != 0 ? TRAP_CAUSE_STORE_ADDRESS_MISALIGNED :
          TRAP_CAUSE_LOAD_ADDRESS_MISALIGNED;
      attempted_memory_address_i = 32'h8000_0103 + 32'(store);
      trap_pc_ex_i = 32'h8000_0080 + 4 * 32'(store);
      trap_taken_i = 1'b1;
      #1ns;
      assert (csr_pc_redirect_address_o == 32'h100);
      @(posedge clk);
      #1ns;
      trap_taken_i  = 1'b0;
      csr_address_i = CSR_ADDRESS_MTVAL;
      #1ns;
      assert (csr_load_data_o == attempted_memory_address_i);
      csr_address_i = CSR_ADDRESS_MEPC;
      #1ns;
      assert (csr_load_data_o == trap_pc_ex_i);
      csr_address_i = CSR_ADDRESS_MCAUSE;
      #1ns;
      assert (csr_load_data_o == (store != 0 ? 32'd6 : 32'd4));
    end

    $display("csr tests passed");
    $finish;
  end
endmodule
