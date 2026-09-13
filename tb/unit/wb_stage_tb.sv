timeunit 1ns / 1ps;

import core_types::*;

module wb_stage_tb;
  logic valid_i;
  writeback_control_t writeback_control_i;
  logic [31:0] alu_result_i;
  logic [31:0] memory_read_data_i;
  logic [31:0] pc_plus_4_i;
  logic [31:0] writeback_data_o;
  logic rf_write_enable_o;

  wb_stage dut (.*);

  initial begin
    $dumpfile("build/tests/wb_stage/waveform.fst");
    $dumpvars(0, wb_stage_tb);

    valid_i = 1'b1;
    alu_result_i = 32'h1234_5678;
    memory_read_data_i = 32'hDEAD_BEEF;
    pc_plus_4_i = 32'h0000_0104;
    writeback_control_i = '0;
    #1ns;

    // Arithmetic instruction: write the ALU result to rd.
    writeback_control_i.register_write_enable = 1'b1;
    writeback_control_i.writeback_source = WRITEBACK_SOURCE_ALU;
    #1ns;
    assert (writeback_data_o == alu_result_i);
    assert (rf_write_enable_o);

    // Load instruction: write memory data to rd.
    writeback_control_i.writeback_source = WRITEBACK_SOURCE_MEMORY;
    #1ns;
    assert (writeback_data_o == memory_read_data_i);
    assert (rf_write_enable_o);

    // Jump instruction: write PC + 4 to rd.
    writeback_control_i.writeback_source = WRITEBACK_SOURCE_PC4;
    #1ns;
    assert (writeback_data_o == pc_plus_4_i);
    assert (rf_write_enable_o);

    // Instruction without register writeback.
    writeback_control_i.register_write_enable = 1'b0;
    #1ns;
    assert (!rf_write_enable_o);

    // Invalid instructions must not write to the register file.
    writeback_control_i.register_write_enable = 1'b1;
    valid_i = 1'b0;
    #1ns;
    assert (!rf_write_enable_o);

    $display("wb_stage tests passed");
    $finish;
  end
endmodule
