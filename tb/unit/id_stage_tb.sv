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
  logic    [ 1:0] alu_src_a_sel;
  logic           alu_src_b_sel;

  logic    [31:0] alu_operand_a;
  logic    [31:0] alu_operand_b;
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

    valid_id      = 1'b0;
    instr_id      = '0;
    pc_id         = 32'h0000_0100;
    wb_wr_data    = '0;
    wb_wr_reg     = '0;
    wb_wr_en      = 1'b0;
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 1'b0;

    write_register(5'd1, 32'h1234_5678);
    write_register(5'd2, 32'h0000_0005);

    // ADD x3, x1, x2: both operands come from the register file.
    valid_id      = 1'b1;
    instr_id      = 32'b0000000_00010_00001_000_00011_0110011;
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 1'b0;
    #1ns;
    assert (alu_operand_a == 32'h1234_5678);
    assert (alu_operand_b == 32'h0000_0005);
    assert (rs1 == 5'd1 && rs2 == 5'd2 && rd == 5'd3);
    assert (alu_op == ALU_ADD);
    assert (pc_id_out == 32'h0000_0100 && valid_id_out == 1'b1);

    // ADDI x3, x1, -4: operand B comes from the sign-extended immediate.
    instr_id      = 32'b111111111100_00001_000_00011_0010011;
    alu_src_b_sel = 1'b1;
    #1ns;
    assert (alu_operand_a == 32'h1234_5678);
    assert (alu_operand_b == 32'hffff_fffc);
    assert (alu_op == ALU_ADD);

    // LUI-style selection: zero plus the upper immediate.
    instr_id      = 32'b00010010001101000101_00011_0110111;
    alu_src_a_sel = 2'b01;
    alu_src_b_sel = 1'b1;
    #1ns;
    assert (alu_operand_a == 32'd0);
    assert (alu_operand_b == 32'h1234_5000);

    // AUIPC-style selection: PC plus the upper immediate.
    alu_src_a_sel = 2'b10;
    #1ns;
    assert (alu_operand_a == 32'h0000_0100);
    assert (alu_operand_b == 32'h1234_5000);

    valid_id = 1'b0;
    #1ns;
    assert (valid_id_out == 1'b0);

    $display("id_stage tests passed");
    $finish;
  end
endmodule
