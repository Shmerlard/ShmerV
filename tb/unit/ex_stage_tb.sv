timeunit 1ns / 1ps;

import core_types::*;

module ex_stage_tb;
  logic                    valid_i;
  logic             [31:0] rs1_data_i;
  logic             [31:0] rs2_data_i;
  logic             [31:0] immediate_i;
  execute_control_t        execute_control_i;
  logic             [31:0] pc_i;
  logic             [31:0] alu_result_o;

  ex_stage dut (.*);

  initial begin
    $dumpfile("build/tests/ex_stage/waveform.fst");
    $dumpvars(0, ex_stage_tb);

    rs1_data_i                             = 32'd10;
    valid_i                                = 1'b1;
    rs2_data_i                             = 32'd3;
    immediate_i                            = 32'd7;
    execute_control_i.alu_operation        = ALU_ADD;
    pc_i                                   = 32'h0000_0100;
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_RS1;
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_RS2;
    #1ns;

    assert (alu_result_o == 32'd13);

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

    $display("ex_stage tests passed");
    $finish;
  end
endmodule
