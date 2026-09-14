timeunit 1ns / 1ps;

import core_types::*;

module controller_tb;
  opcode_t opcode_i;
  logic [2:0] funct3_i;
  logic [6:0] funct7_i;

  execute_control_t execute_control_o;
  memory_control_t memory_control_o;
  writeback_control_t writeback_control_o;

  controller dut (.*);

  task automatic check_branch(input logic [2:0] funct3,
                              input pc_redirect_condition_t expected_condition);
    begin
      opcode_i = OPCODE_BRANCH;
      funct3_i = funct3;
      #1ns;
      assert (execute_control_o.alu_operation == ALU_SUB);
      assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
      assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_RS2);
      assert (execute_control_o.pc_redirect_condition == expected_condition);
      assert (execute_control_o.pc_redirect_address_source == PC_REDIRECT_ADDRESS_PC_IMMEDIATE);
      assert (memory_control_o == '0);
      assert (!writeback_control_o.register_write_enable);
    end
  endtask

  initial begin
    $dumpfile("build/tests/controller/waveform.fst");
    $dumpvars(0, controller_tb);

    // ADD: register operands, ALU result written to the register file.
    opcode_i = OPCODE_REG;
    funct3_i = 3'b000;
    funct7_i = 7'b0000000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_RS2);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);
    assert (memory_control_o == '0);

    // SUB: funct7 selects subtraction.
    funct7_i = 7'b0100000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_SUB);

    // ADDI: the second ALU operand comes from the immediate.
    opcode_i = OPCODE_IMM;
    funct3_i = 3'b000;
    funct7_i = 7'b0000000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (writeback_control_o.register_write_enable);

    // Load: calculate an address, read memory, and write memory data to rd.
    opcode_i = OPCODE_LOAD;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (memory_control_o.memory_read_enable);
    assert (!memory_control_o.memory_write_enable);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_MEMORY);

    // Store: calculate an address and write memory without register writeback.
    opcode_i = OPCODE_STORE;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (!memory_control_o.memory_read_enable);
    assert (memory_control_o.memory_write_enable);
    assert (!writeback_control_o.register_write_enable);

    // JAL: redirect to PC + immediate and write PC + 4 to rd.
    opcode_i = OPCODE_JAL;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_PC);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_ALWAYS);
    assert (execute_control_o.pc_redirect_address_source == PC_REDIRECT_ADDRESS_PC_IMMEDIATE);
    assert (!execute_control_o.pc_redirect_zero_lsb);
    assert (memory_control_o == '0);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_PC4);

    // JALR: redirect to rs1 + immediate and write PC + 4 to rd.
    opcode_i = OPCODE_JALR;
    funct3_i = 3'b000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_ALWAYS);
    assert (execute_control_o.pc_redirect_address_source == PC_REDIRECT_ADDRESS_ALU_RESULT);
    assert (execute_control_o.pc_redirect_zero_lsb);
    assert (memory_control_o == '0);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_PC4);

    // JALR encodings with a nonzero funct3 are invalid.
    funct3_i = 3'b001;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    assert (!execute_control_o.pc_redirect_zero_lsb);
    assert (!writeback_control_o.register_write_enable);

    // LUI: write the upper immediate to rd through the ALU.
    opcode_i = OPCODE_LUI;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_ZERO);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    assert (memory_control_o == '0);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);

    // AUIPC: add the upper immediate to PC and write the ALU result to rd.
    opcode_i = OPCODE_AUIPC;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_PC);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    assert (memory_control_o == '0);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);

    // Conditional branches.
    check_branch(3'b000, PC_REDIRECT_EQ);
    check_branch(3'b001, PC_REDIRECT_NEQ);
    check_branch(3'b100, PC_REDIRECT_LT);
    check_branch(3'b101, PC_REDIRECT_GE);
    check_branch(3'b110, PC_REDIRECT_ULT);
    check_branch(3'b111, PC_REDIRECT_UGE);

    // Reserved branch funct3 encodings are invalid.
    opcode_i = OPCODE_BRANCH;
    funct3_i = 3'b010;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);

    funct3_i = 3'b011;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);

    // Unknown opcode: no memory or register writes are allowed.
    opcode_i = opcode_t'(7'b1111111);
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (memory_control_o == '0);
    assert (writeback_control_o == '0);

    $display("controller tests passed");
    $finish;
  end
endmodule
