timeunit 1ns / 1ps;

import core_types::*;
import csr_types::*;

module csr_tb;
  logic clk = 1'b0;
  logic rst;
  logic csr_read_enable_i;
  logic csr_write_enable_i;
  logic trap_taken_i;
  logic [31:0] trap_pc_ex_i;
  trap_type_t trap_type_i;
  trap_cause_exception_t trap_cause_exception_i;
  logic [31:0] trap_instruction_ex_i;
  logic [11:0] csr_address_i;
  logic [31:0] csr_write_data_i;
  logic [31:0] csr_load_data_o;

  csr dut (.*);

  always #5ns clk = ~clk;

  initial begin
    $dumpfile("build/tests/csr/waveform.fst");
    $dumpvars(0, csr_tb);

    rst = 1'b1;
    csr_read_enable_i = 1'b0;
    csr_write_enable_i = 1'b0;
    trap_taken_i = 1'b0;
    trap_pc_ex_i = '0;
    trap_type_i = TRAP_TYPE_EXCEPTION;
    trap_cause_exception_i = TRAP_CAUSE_ILLEGAL_INSTRUCTION;
    trap_instruction_ex_i = '0;
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
    assert (csr_load_data_o == 32'h0000_0000)
    else $fatal(1, "mtvec old value was %h", csr_load_data_o);

    @(posedge clk);
    #1ns;
    csr_write_enable_i = 1'b0;
    assert (csr_load_data_o == 32'h0000_0100)
    else $fatal(1, "mtvec write produced %h", csr_load_data_o);

    // A disabled write must preserve the CSR value.
    csr_write_data_i = 32'h0000_0200;
    @(posedge clk);
    #1ns;
    assert (csr_load_data_o == 32'h0000_0100)
    else $fatal(1, "disabled write changed mtvec to %h", csr_load_data_o);

    $display("csr tests passed");
    $finish;
  end
endmodule
