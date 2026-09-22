timeunit 1ns / 1ps;

import core_types::*;

module mem_stage_tb;
  logic valid_i;
  memory_control_t memory_control_i;
  writeback_control_t writeback_control_i;
  logic [31:0] alu_result_i;
  logic [31:0] pc_plus_4_i;
  logic [31:0] store_data_in_mem_i;
  logic [31:0] memory_address_o;
  logic [3:0] memory_write_byte_enable_o;
  logic memory_read_enable_o;
  logic memory_write_enable_o;
  logic [31:0] memory_store_data_o;
  logic [31:0] memory_load_data_i;
  logic [31:0] memory_load_data_out_mem_o;
  logic csr_read_enable_o;
  logic csr_write_enable_o;
  logic [11:0] csr_address_i;
  logic [11:0] csr_address_o;
  logic [31:0] csr_store_data_o;
  logic [31:0] csr_load_data_i;
  logic [31:0] csr_load_data_out_mem_o;
  logic [31:0] forward_data_o;

  mem_stage dut (.*);

  initial begin
    $dumpfile("build/tests/mem_stage/waveform.fst");
    $dumpvars(0, mem_stage_tb);

    valid_i = 1'b1;
    alu_result_i = 32'h0000_0108;
    pc_plus_4_i = 32'h0000_0104;
    store_data_in_mem_i = 32'hAABB_CCDD;
    memory_control_i = '0;
    writeback_control_i = '0;
    memory_load_data_i = 32'hDEAD_BEEF;
    csr_address_i = 12'h300;
    csr_load_data_i = 32'hCAFE_BABE;
    #1ns;

    // Arithmetic instruction: memory remains disabled.
    assert (!memory_read_enable_o && !memory_write_enable_o);

    // Byte stores select and align each byte lane.
    memory_control_i.memory_write_enable = 1'b1;
    memory_control_i.access_size = MEMORY_ACCESS_BYTE;
    for (int offset = 0; offset < 4; offset++) begin
      alu_result_i = 32'h0000_0100 + offset;
      #1ns;
      assert (memory_address_o == alu_result_i);
      assert (memory_store_data_o == (store_data_in_mem_i << (8 * offset)));
      assert (memory_write_byte_enable_o == (4'b0001 << offset));
      assert (memory_write_enable_o);
    end

    // Aligned halfword stores select the lower or upper two lanes.
    memory_control_i.access_size = MEMORY_ACCESS_HALF;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (memory_store_data_o == store_data_in_mem_i);
    assert (memory_write_byte_enable_o == 4'b0011);
    assert (memory_write_enable_o);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (memory_store_data_o == 32'hCCDD_0000);
    assert (memory_write_byte_enable_o == 4'b1100);
    assert (memory_write_enable_o);

    // Misaligned halfword stores are suppressed.
    alu_result_i = 32'h0000_0101;
    #1ns;
    assert (memory_write_byte_enable_o == 4'b0000);
    assert (!memory_write_enable_o);

    // Word stores require a word-aligned address and enable every lane.
    memory_control_i.access_size = MEMORY_ACCESS_WORD;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (memory_store_data_o == store_data_in_mem_i);
    assert (memory_write_byte_enable_o == 4'b1111);
    assert (memory_write_enable_o);

    alu_result_i = 32'h0000_0102;
    #1ns;
    assert (memory_write_byte_enable_o == 4'b0000);
    assert (!memory_write_enable_o);

    // Load instruction: only the memory read control is enabled.
    memory_control_i.memory_write_enable = 1'b0;
    memory_control_i.memory_read_enable = 1'b1;
    memory_control_i.access_size = MEMORY_ACCESS_WORD;
    alu_result_i = 32'h0000_0100;
    #1ns;
    assert (memory_read_enable_o);
    assert (!memory_write_enable_o);
    assert (memory_load_data_out_mem_o == memory_load_data_i);

    // CSR signals are passed through and gated by valid.
    memory_control_i.memory_read_enable = 1'b0;
    memory_control_i.csr_read_enable = 1'b1;
    memory_control_i.csr_write_enable = 1'b1;
    #1ns;
    assert (csr_read_enable_o);
    assert (csr_write_enable_o);
    assert (csr_address_o == csr_address_i);
    assert (csr_store_data_o == store_data_in_mem_i);
    assert (csr_load_data_out_mem_o == csr_load_data_i);

    $display("mem_stage tests passed");
    $finish;
  end
endmodule
