timeunit 1ns / 1ps;

import core_types::*;

module mem_stage_tb;
  logic [31:0] alu_result_i;
  logic [31:0] rs2_data_i;
  logic [31:0] memory_read_data_i;
  memory_control_t memory_control_i;
  logic [31:0] memory_address_o;
  logic [31:0] memory_write_data_o;
  logic memory_read_enable_o;
  logic memory_write_enable_o;
  logic [31:0] memory_read_data_o;

  mem_stage dut (.*);

  initial begin
    $dumpfile("build/mem_stage.fst");
    $dumpvars(0, mem_stage_tb);

    alu_result_i = 32'h0000_0108;
    rs2_data_i = 32'hAABB_CCDD;
    memory_read_data_i = 32'hDEAD_BEEF;
    memory_control_i = '0;
    #1ns;

    // Arithmetic instruction: memory remains disabled.
    assert (!memory_read_enable_o && !memory_write_enable_o);

    // Store instruction: address, store data, and write control reach memory.
    memory_control_i.memory_write_enable = 1'b1;
    #1ns;
    assert (memory_address_o == alu_result_i);
    assert (memory_write_data_o == rs2_data_i);
    assert (memory_write_enable_o);

    // Load instruction: memory data and read control pass through.
    memory_control_i.memory_write_enable = 1'b0;
    memory_control_i.memory_read_enable  = 1'b1;
    #1ns;
    assert (memory_read_enable_o);
    assert (!memory_write_enable_o);
    assert (memory_read_data_o == memory_read_data_i);

    $display("mem_stage tests passed");
    $finish;
  end
endmodule
