timeunit 1ns / 1ps;

import core_types::*;

module ex_stage_tb;
  logic               [31:0] rs1_data_i;
  logic               [31:0] rs2_data_i;
  logic               [31:0] immediate_i;
  execute_control_t          execute_control_i;
  memory_control_t           memory_control_i;
  memory_control_t           memory_control_o;
  writeback_control_t        writeback_control_i;
  writeback_control_t        writeback_control_o;
  logic                      valid_i;
  logic               [31:0] pc_i;
  logic               [ 4:0] rs1_i;
  logic               [ 4:0] rs2_i;
  logic               [ 4:0] rd_i;

  logic                      valid_o;
  logic               [31:0] pc_o;
  logic               [ 4:0] rs1_o;
  logic               [ 4:0] rs2_o;
  logic               [ 4:0] rd_o;
  logic               [31:0] rs2_data_o;
  logic               [31:0] alu_result_o;

  ex_stage dut (.*);

  initial begin
    $dumpfile("build/ex_stage.fst");
    $dumpvars(0, ex_stage_tb);

    rs1_data_i                             = 32'd10;
    rs2_data_i                             = 32'd3;
    immediate_i                            = 32'd7;
    execute_control_i.alu_operation        = ALU_ADD;
    valid_i                                = 1'b1;
    pc_i                                   = 32'h0000_0100;
    rs1_i                                  = 5'd1;
    rs2_i                                  = 5'd2;
    rd_i                                   = 5'd3;
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_RS1;
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_RS2;
    memory_control_i                       = '0;
    writeback_control_i                    = '0;
    #1ns;

    assert (alu_result_o == 32'd13);
    assert (valid_o == valid_i && pc_o == pc_i);
    assert (rs1_o == rs1_i && rs2_o == rs2_i);
    assert (rd_o == rd_i && rs2_data_o == rs2_data_i);
    assert (memory_control_o == memory_control_i);
    assert (writeback_control_o == writeback_control_i);

    // Register plus immediate.
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_IMM;
    #1ns;
    assert (alu_result_o == 32'd17);

    // Zero plus immediate, used by LUI.
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_ZERO;
    #1ns;
    assert (alu_result_o == 32'd7);

    // PC plus immediate, used by AUIPC.
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_PC;
    #1ns;
    assert (alu_result_o == 32'h0000_0107);

    // Check that the selected operands work with another ALU operation.
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_RS1;
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_RS2;
    execute_control_i.alu_operation = ALU_SUB;
    #1ns;
    assert (alu_result_o == 32'd7);

    valid_i = 1'b0;
    #1ns;
    assert (valid_o == 1'b0);

    $display("ex_stage tests passed");
    $finish;
  end
endmodule
