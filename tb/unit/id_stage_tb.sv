timeunit 1ns / 1ps;

import core_types::*;

module id_stage_tb;
  logic                      clk = 1'b0;
  logic               [31:0] instruction_id_i;
  logic               [31:0] pc_id_i;
  logic               [31:0] writeback_data_i;
  logic               [ 4:0] writeback_rd_i;
  logic                      writeback_write_enable_i;

  logic               [31:0] rs1_data_o;
  logic               [31:0] rs2_data_o;
  logic               [31:0] immediate_o;
  logic               [ 4:0] rd_o;
  logic               [ 4:0] rs1_o;
  logic               [ 4:0] rs2_o;
  execute_control_t          execute_control_o;
  memory_control_t           memory_control_o;
  writeback_control_t        writeback_control_o;

  id_stage dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic [4:0] address, input logic [31:0] value);
    @(negedge clk);
    writeback_write_enable_i = 1'b1;
    writeback_rd_i = address;
    writeback_data_i = value;
    @(posedge clk);
    #1ns;
    writeback_write_enable_i = 1'b0;
  endtask

  initial begin
    $dumpfile("build/id_stage.fst");
    $dumpvars(0, id_stage_tb);

    instruction_id_i         = '0;
    pc_id_i                  = 32'h0000_0100;
    writeback_data_i         = '0;
    writeback_rd_i           = '0;
    writeback_write_enable_i = 1'b0;

    write_register(5'd1, 32'h1234_5678);
    write_register(5'd2, 32'h0000_0005);

    // ADD x3, x1, x2: both operands come from the register file.
    instruction_id_i = 32'b0000000_00010_00001_000_00011_0110011;
    #1ns;
    assert (rs1_data_o == 32'h1234_5678);
    assert (rs2_data_o == 32'h0000_0005);
    assert (rs1_o == 5'd1 && rs2_o == 5'd2 && rd_o == 5'd3);
    assert (execute_control_o.alu_operation == ALU_ADD);

    // ADDI x3, x1, -4: operand B comes from the sign-extended immediate.
    instruction_id_i = 32'b111111111100_00001_000_00011_0010011;
    #1ns;
    assert (rs1_data_o == 32'h1234_5678);
    assert (immediate_o == 32'hffff_fffc);
    assert (execute_control_o.alu_operation == ALU_ADD);

    // U-type immediate generation.
    instruction_id_i = 32'b00010010001101000101_00011_0110111;
    #1ns;
    assert (immediate_o == 32'h1234_5000);

    $display("id_stage tests passed");
    $finish;
  end
endmodule
