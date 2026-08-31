timeunit 1ns / 1ps;

import core_types::*;

module id_stage_tb;
  logic           clk = 1'b0;
  logic           valid_id;
  logic    [31:0] instr_id;
  logic    [31:0] pc_id;
  logic    [31:0] wb_wr_data;
  logic    [ 4:0] wb_wr_reg;
  logic           wb_wr_en;

  logic    [31:0] rs1_data;
  logic    [31:0] rs2_data;
  logic    [31:0] imm;
  logic    [ 4:0] rd;
  logic    [ 4:0] rs1;
  logic    [ 4:0] rs2;
  alu_op_t        alu_op;
  logic    [31:0] pc_id_out;
  logic           valid_id_out;

  id_stage dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic [4:0] addr, input logic [31:0] data);
    @(negedge clk);
    wb_wr_en   = 1'b1;
    wb_wr_reg  = addr;
    wb_wr_data = data;
    @(posedge clk);
    #1ns;
    wb_wr_en = 1'b0;
  endtask

  initial begin
    $dumpfile("build/id_stage.fst");
    $dumpvars(0, id_stage_tb);

    valid_id   = 1'b0;
    instr_id   = '0;
    pc_id      = 32'h0000_0100;
    wb_wr_data = '0;
    wb_wr_reg  = '0;
    wb_wr_en   = 1'b0;

    write_register(5'd1, 32'h1234_5678);
    write_register(5'd2, 32'h0000_0005);

    // ADD x3, x1, x2: both operands come from the register file.
    valid_id = 1'b1;
    instr_id = 32'b0000000_00010_00001_000_00011_0110011;
    #1ns;
    assert (rs1_data == 32'h1234_5678);
    assert (rs2_data == 32'h0000_0005);
    assert (rs1 == 5'd1 && rs2 == 5'd2 && rd == 5'd3);
    assert (alu_op == ALU_ADD);
    assert (pc_id_out == 32'h0000_0100 && valid_id_out == 1'b1);

    // ADDI x3, x1, -4: operand B comes from the sign-extended immediate.
    instr_id = 32'b111111111100_00001_000_00011_0010011;
    #1ns;
    assert (rs1_data == 32'h1234_5678);
    assert (imm == 32'hffff_fffc);
    assert (alu_op == ALU_ADD);

    // U-type immediate generation.
    instr_id = 32'b00010010001101000101_00011_0110111;
    #1ns;
    assert (imm == 32'h1234_5000);

    valid_id = 1'b0;
    #1ns;
    assert (valid_id_out == 1'b0);

    $display("id_stage tests passed");
    $finish;
  end
endmodule
