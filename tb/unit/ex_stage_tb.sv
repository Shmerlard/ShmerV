timeunit 1ns / 1ps;

import core_types::*;

module ex_stage_tb;
  logic    [31:0] rs1_data;
  logic    [31:0] rs2_data;
  logic    [31:0] imm;
  logic    [ 1:0] alu_src_a_sel;
  logic           alu_src_b_sel;
  alu_op_t        alu_op;
  logic           valid_ex_in;
  logic    [31:0] pc_in;
  logic    [ 4:0] rs1_reg_in;
  logic    [ 4:0] rs2_reg_in;
  logic    [ 4:0] rd_reg_in;

  logic           valid_ex_out;
  logic    [31:0] pc_out;
  logic    [ 4:0] rs1_reg_out;
  logic    [ 4:0] rs2_reg_out;
  logic    [ 4:0] rd_reg_out;
  logic    [31:0] rs2_data_out;
  logic    [31:0] alu_output;

  ex_stage dut (.*);

  initial begin
    $dumpfile("build/ex_stage.fst");
    $dumpvars(0, ex_stage_tb);

    rs1_data      = 32'd10;
    rs2_data      = 32'd3;
    imm           = 32'd7;
    alu_op        = ALU_ADD;
    valid_ex_in   = 1'b1;
    pc_in         = 32'h0000_0100;
    rs1_reg_in    = 5'd1;
    rs2_reg_in    = 5'd2;
    rd_reg_in     = 5'd3;
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 1'b0;
    #1ns;

    assert (alu_output == 32'd13);
    assert (valid_ex_out == valid_ex_in && pc_out == pc_in);
    assert (rs1_reg_out == rs1_reg_in && rs2_reg_out == rs2_reg_in);
    assert (rd_reg_out == rd_reg_in && rs2_data_out == rs2_data);

    // Register plus immediate.
    alu_src_b_sel = 1'b1;
    #1ns;
    assert (alu_output == 32'd17);

    // Zero plus immediate, used by LUI.
    alu_src_a_sel = 2'b01;
    #1ns;
    assert (alu_output == 32'd7);

    // PC plus immediate, used by AUIPC.
    alu_src_a_sel = 2'b10;
    #1ns;
    assert (alu_output == 32'h0000_0107);

    // Check that the selected operands work with another ALU operation.
    alu_src_a_sel = 2'b00;
    alu_src_b_sel = 1'b0;
    alu_op        = ALU_SUB;
    #1ns;
    assert (alu_output == 32'd7);

    valid_ex_in = 1'b0;
    #1ns;
    assert (valid_ex_out == 1'b0);

    $display("ex_stage tests passed");
    $finish;
  end
endmodule
