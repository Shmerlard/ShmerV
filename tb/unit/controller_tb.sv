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
    assert (execute_control_o.pc_redirect_enable);
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
    assert (execute_control_o.pc_redirect_enable);
    assert (execute_control_o.pc_redirect_zero_lsb);
    assert (memory_control_o == '0);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_PC4);

    // JALR encodings with a nonzero funct3 are invalid.
    funct3_i = 3'b001;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (!execute_control_o.pc_redirect_enable);
    assert (!execute_control_o.pc_redirect_zero_lsb);
    assert (!writeback_control_o.register_write_enable);

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
