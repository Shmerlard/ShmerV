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
  logic             [31:0] pc_plus_4_data_o;
  logic                    pc_redirect_enable_o;
  logic             [31:0] pc_redirect_address_o;

  ex_stage dut (.*);

  task automatic check_branch(input pc_redirect_condition_t condition, input logic [31:0] operand_a,
                              input logic [31:0] operand_b, input logic expected_taken);
    begin
      valid_i                                      = 1'b1;
      rs1_data_i                                   = operand_a;
      rs2_data_i                                   = operand_b;
      immediate_i                                  = 32'h20;
      execute_control_i.alu_operand_a_select       = ALU_OPERAND_A_RS1;
      execute_control_i.alu_operand_b_select       = ALU_OPERAND_B_RS2;
      execute_control_i.alu_operation              = ALU_SUB;
      execute_control_i.pc_redirect_condition      = condition;
      execute_control_i.pc_redirect_address_source = PC_REDIRECT_ADDRESS_PC_IMMEDIATE;
      execute_control_i.pc_redirect_zero_lsb       = 1'b0;
      #1ns;
      assert (pc_redirect_enable_o == expected_taken);
      assert (pc_redirect_address_o == pc_i + immediate_i);
    end
  endtask

  initial begin
    $dumpfile("build/tests/ex_stage/waveform.fst");
    $dumpvars(0, ex_stage_tb);

    rs1_data_i                             = 32'd10;
    valid_i                                = 1'b1;
    rs2_data_i                             = 32'd3;
    immediate_i                            = 32'd7;
    execute_control_i                      = '0;
    execute_control_i.alu_operation        = ALU_ADD;
    pc_i                                   = 32'h0000_0100;
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_RS1;
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_RS2;
    #1ns;

    assert (alu_result_o == 32'd13);
    assert (pc_plus_4_data_o == 32'h0000_0104);
    assert (!pc_redirect_enable_o);

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

    // A valid jump redirects the PC to the ALU result.
    execute_control_i.pc_redirect_condition = PC_REDIRECT_ALWAYS;
    execute_control_i.pc_redirect_address_source = PC_REDIRECT_ADDRESS_ALU_RESULT;
    #1ns;
    assert (pc_redirect_enable_o);
    assert (pc_redirect_address_o == 32'h0000_0107);

    // JALR clears bit 0 of an odd redirect address.
    execute_control_i.pc_redirect_zero_lsb = 1'b1;
    #1ns;
    assert (pc_redirect_address_o == 32'h0000_0106);

    execute_control_i.pc_redirect_zero_lsb = 1'b0;

    // An invalid jump cannot redirect the PC.
    valid_i = 1'b0;
    #1ns;
    assert (!pc_redirect_enable_o);

    valid_i = 1'b1;
    execute_control_i.pc_redirect_condition = PC_REDIRECT_NEVER;

    // Check that the selected operands work with another ALU operation.
    execute_control_i.alu_operand_a_select = ALU_OPERAND_A_RS1;
    execute_control_i.alu_operand_b_select = ALU_OPERAND_B_RS2;
    execute_control_i.alu_operation = ALU_SUB;
    #1ns;
    assert (alu_result_o == 32'd7);

    // Taken and not-taken branch conditions.
    check_branch(PC_REDIRECT_EQ, 32'd5, 32'd5, 1'b1);
    check_branch(PC_REDIRECT_EQ, 32'd5, 32'd6, 1'b0);
    check_branch(PC_REDIRECT_NEQ, 32'd5, 32'd6, 1'b1);
    check_branch(PC_REDIRECT_NEQ, 32'd5, 32'd5, 1'b0);
    check_branch(PC_REDIRECT_LT, 32'hFFFF_FFFF, 32'd1, 1'b1);
    check_branch(PC_REDIRECT_LT, 32'd1, 32'hFFFF_FFFF, 1'b0);
    check_branch(PC_REDIRECT_GE, 32'd1, 32'hFFFF_FFFF, 1'b1);
    check_branch(PC_REDIRECT_GE, 32'hFFFF_FFFF, 32'd1, 1'b0);
    check_branch(PC_REDIRECT_ULT, 32'd1, 32'hFFFF_FFFF, 1'b1);
    check_branch(PC_REDIRECT_ULT, 32'hFFFF_FFFF, 32'd1, 1'b0);
    check_branch(PC_REDIRECT_UGE, 32'hFFFF_FFFF, 32'd1, 1'b1);
    check_branch(PC_REDIRECT_UGE, 32'd1, 32'hFFFF_FFFF, 1'b0);

    // Invalid instructions cannot take an otherwise unconditional redirect.
    execute_control_i.pc_redirect_condition = PC_REDIRECT_ALWAYS;
    valid_i = 1'b0;
    #1ns;
    assert (!pc_redirect_enable_o);

    $display("ex_stage tests passed");
    $finish;
  end
endmodule
