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
    writeback_control_i.memory_access_size = MEMORY_ACCESS_INVALID;
    #1ns;

    // Arithmetic instruction: write the ALU result to rd.
    writeback_control_i.register_write_enable = 1'b1;
    writeback_control_i.writeback_source = WRITEBACK_SOURCE_ALU;
    #1ns;
    assert (writeback_data_o == alu_result_i);
    assert (rf_write_enable_o);

    // Load instruction: write memory data to rd.
    writeback_control_i.writeback_source   = WRITEBACK_SOURCE_MEMORY;
    writeback_control_i.memory_access_size = MEMORY_ACCESS_WORD;
    #1ns;
    assert (writeback_data_o == memory_read_data_i);
    assert (rf_write_enable_o);

    // Signed and unsigned byte loads use the address byte offset.
    memory_read_data_i = 32'h80_7F_01_FF;
    writeback_control_i.memory_access_size = MEMORY_ACCESS_BYTE;
    writeback_control_i.load_unsigned = 1'b0;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (writeback_data_o == 32'hFFFF_FFFF);

    alu_result_i = 32'h0000_0101;
    #1ns;
    assert (writeback_data_o == 32'h0000_0001);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (writeback_data_o == 32'h0000_007F);

    alu_result_i = 32'h0000_0103;
    #1ns;
    assert (writeback_data_o == 32'hFFFF_FF80);

    writeback_control_i.load_unsigned = 1'b1;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (writeback_data_o == 32'h0000_00FF);

    alu_result_i = 32'h0000_0101;
    #1ns;
    assert (writeback_data_o == 32'h0000_0001);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (writeback_data_o == 32'h0000_007F);

    alu_result_i = 32'h0000_0103;
    #1ns;
    assert (writeback_data_o == 32'h0000_0080);

    // Signed and unsigned halfword loads use the same byte-based offset.
    writeback_control_i.memory_access_size = MEMORY_ACCESS_HALF;
    writeback_control_i.load_unsigned = 1'b0;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (writeback_data_o == 32'h0000_01FF);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (writeback_data_o == 32'hFFFF_807F);

    writeback_control_i.load_unsigned = 1'b1;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (writeback_data_o == 32'h0000_01FF);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (writeback_data_o == 32'h0000_807F);

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
