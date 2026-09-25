timeunit 1ns / 1ps;

import core_types::*;
import csr_types::*;

module controller_tb;
  opcode_t opcode_i;
  logic [2:0] funct3_i;
  logic [6:0] funct7_i;
  logic [11:0] funct12_i;
  logic [4:0] rs1_i;
  logic [4:0] rd_i;

  execute_control_t execute_control_o;
  memory_control_t memory_control_o;
  writeback_control_t writeback_control_o;
  system_operation_t system_operation_o;
  logic uses_rs1_o;
  logic uses_rs2_o;
  logic instruction_invalid_o;
  logic illegal_instruction_o;

  assign instruction_invalid_o = illegal_instruction_o;

  controller dut (.*);

  task automatic check_memory_disabled;
    assert (!memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_INVALID);
  endtask

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
      check_memory_disabled();
      assert (!writeback_control_o.register_write_enable);
      assert (uses_rs1_o);
      assert (uses_rs2_o);
    end
  endtask

  initial begin
    $dumpfile("build/tests/controller/waveform.fst");
    $dumpvars(0, controller_tb);

    // ADD: register operands, ALU result written to the register file.
    opcode_i = OPCODE_REG;
    funct3_i = 3'b000;
    funct7_i = 7'b0000000;
    funct12_i = 12'b0;
    rs1_i = 5'd1;
    rd_i = 5'd2;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_RS2);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);
    check_memory_disabled();
    assert (uses_rs1_o);
    assert (uses_rs2_o);

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
    assert (uses_rs1_o);
    assert (!uses_rs2_o);

    // Byte load: calculate an address, read memory, and write memory data to rd.
    opcode_i = OPCODE_LOAD;
    funct3_i = 3'b000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (memory_control_o.target == MEMORY_TARGET_DMEMORY);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_MEMORY);
    assert (memory_control_o.access_size == MEMORY_ACCESS_BYTE);
    assert (writeback_control_o.memory_access_size == MEMORY_ACCESS_BYTE);
    assert (!writeback_control_o.load_unsigned);
    assert (uses_rs1_o);
    assert (!uses_rs2_o);

    funct3_i = 3'b001;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_HALF);
    assert (writeback_control_o.register_write_enable);

    funct3_i = 3'b010;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_WORD);
    assert (writeback_control_o.register_write_enable);

    funct3_i = 3'b100;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_BYTE);
    assert (writeback_control_o.memory_access_size == MEMORY_ACCESS_BYTE);
    assert (writeback_control_o.load_unsigned);
    assert (writeback_control_o.register_write_enable);

    funct3_i = 3'b101;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_HALF);
    assert (writeback_control_o.memory_access_size == MEMORY_ACCESS_HALF);
    assert (writeback_control_o.load_unsigned);
    assert (writeback_control_o.register_write_enable);

    // Unsupported load widths have no architectural side effects.
    funct3_i = 3'b011;
    #1ns;
    assert (!memory_control_o.read_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_INVALID);
    assert (!writeback_control_o.register_write_enable);

    // Byte store: calculate an address and write without register writeback.
    opcode_i = OPCODE_STORE;
    funct3_i = 3'b000;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_RS1);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (!memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.target == MEMORY_TARGET_DMEMORY);
    assert (memory_control_o.access_size == MEMORY_ACCESS_BYTE);
    assert (!writeback_control_o.register_write_enable);
    assert (uses_rs1_o);
    assert (uses_rs2_o);

    funct3_i = 3'b001;
    #1ns;
    assert (memory_control_o.write_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_HALF);

    funct3_i = 3'b010;
    #1ns;
    assert (memory_control_o.write_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_WORD);

    // Unsupported store widths cannot write memory.
    funct3_i = 3'b011;
    #1ns;
    assert (!memory_control_o.write_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_INVALID);

    funct3_i = 3'b100;
    #1ns;
    assert (!memory_control_o.write_enable);
    assert (memory_control_o.access_size == MEMORY_ACCESS_INVALID);

    // JAL: redirect to PC + immediate and write PC + 4 to rd.
    opcode_i = OPCODE_JAL;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_PC);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_ALWAYS);
    assert (execute_control_o.pc_redirect_address_source == PC_REDIRECT_ADDRESS_PC_IMMEDIATE);
    assert (!execute_control_o.pc_redirect_zero_lsb);
    check_memory_disabled();
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_PC4);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);

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
    check_memory_disabled();
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_PC4);
    assert (uses_rs1_o);
    assert (!uses_rs2_o);

    // JALR encodings with a nonzero funct3 are invalid.
    funct3_i = 3'b001;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    assert (!execute_control_o.pc_redirect_zero_lsb);
    assert (!writeback_control_o.register_write_enable);
    assert (instruction_invalid_o);

    // Exact funct12 encodings select the supported non-CSR SYSTEM operations.
    opcode_i  = OPCODE_SYSTEM;
    funct3_i  = 3'b000;
    funct12_i = 12'h000;
    rs1_i     = 5'b0;
    rd_i      = 5'b0;
    #1ns;
    assert (system_operation_o == SYSTEM_OPERATION_ECALL);
    assert (!instruction_invalid_o);

    funct12_i = 12'h001;
    #1ns;
    assert (system_operation_o == SYSTEM_OPERATION_EBREAK);
    assert (!instruction_invalid_o);

    funct12_i = 12'h302;
    #1ns;
    assert (system_operation_o == SYSTEM_OPERATION_MRET);
    assert (!instruction_invalid_o);

    funct12_i = 12'h123;
    #1ns;
    assert (system_operation_o == SYSTEM_OPERATION_NONE);
    assert (instruction_invalid_o);

    // LUI: write the upper immediate to rd through the ALU.
    opcode_i = OPCODE_LUI;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_ZERO);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    check_memory_disabled();
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);

    // AUIPC: add the upper immediate to PC and write the ALU result to rd.
    opcode_i = OPCODE_AUIPC;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_ADD);
    assert (execute_control_o.alu_operand_a_select == ALU_OPERAND_A_PC);
    assert (execute_control_o.alu_operand_b_select == ALU_OPERAND_B_IMM);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    check_memory_disabled();
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_ALU);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);

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
    assert (instruction_invalid_o);

    funct3_i = 3'b011;
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    assert (execute_control_o.pc_redirect_condition == PC_REDIRECT_NEVER);
    assert (instruction_invalid_o);

    // CSRRW: select the CSR interface and exchange the CSR with rs1.
    opcode_i = OPCODE_SYSTEM;
    funct3_i = CSR_INSTRUCTION_CSRRW;
    rs1_i = 5'd1;
    rd_i = 5'd2;
    #1ns;
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_REPLACE);
    assert (execute_control_o.store_data_select == STORE_DATA_FORWARDED_RS1);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // rd=x0 suppresses the CSR read but not the CSR write.
    rd_i = 5'd0;
    #1ns;
    assert (!memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (!writeback_control_o.register_write_enable);
    assert (uses_rs1_o);

    // rs1=x0 still writes zero and does not suppress the CSR read.
    rs1_i = 5'd0;
    rd_i  = 5'd2;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);

    // CSRRS reads the CSR and sets the bits selected by rs1.
    funct3_i = CSR_INSTRUCTION_CSRRS;
    rs1_i = 5'd1;
    rd_i = 5'd2;
    #1ns;
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_SET);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // CSRRS with rs1=x0 reads without writing the CSR.
    rs1_i = 5'd0;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (writeback_control_o.register_write_enable);

    // CSRRS with rd=x0 still reads and modifies the CSR.
    rs1_i = 5'd1;
    rd_i  = 5'd0;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (!writeback_control_o.register_write_enable);

    // CSRRC reads the CSR and clears the bits selected by rs1.
    funct3_i = CSR_INSTRUCTION_CSRRC;
    rs1_i = 5'd1;
    rd_i = 5'd2;
    #1ns;
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_CLEAR);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // CSRRC with rs1=x0 reads without writing the CSR.
    rs1_i = 5'd0;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (writeback_control_o.register_write_enable);

    // CSRRWI replaces the CSR with the zero-extended immediate.
    funct3_i = CSR_INSTRUCTION_CSRRWI;
    rs1_i = 5'd21;
    rd_i = 5'd2;
    #1ns;
    assert (execute_control_o.store_data_select == STORE_DATA_CSR_IMMEDIATE);
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_REPLACE);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // CSRRWI with rd=x0 suppresses the read but still writes the immediate.
    rd_i = 5'd0;
    #1ns;
    assert (!memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (!writeback_control_o.register_write_enable);

    // CSRRSI sets the bits selected by the immediate.
    funct3_i = CSR_INSTRUCTION_CSRRSI;
    rs1_i = 5'd8;
    rd_i = 5'd2;
    #1ns;
    assert (execute_control_o.store_data_select == STORE_DATA_CSR_IMMEDIATE);
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_SET);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // CSRRSI with zimm=0 reads without writing the CSR.
    rs1_i = 5'd0;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (writeback_control_o.register_write_enable);

    // CSRRCI clears the bits selected by the immediate.
    funct3_i = CSR_INSTRUCTION_CSRRCI;
    rs1_i = 5'd4;
    #1ns;
    assert (execute_control_o.store_data_select == STORE_DATA_CSR_IMMEDIATE);
    assert (memory_control_o.target == MEMORY_TARGET_CSR);
    assert (memory_control_o.read_enable);
    assert (memory_control_o.write_enable);
    assert (memory_control_o.csr_write_operation == CSR_WRITE_CLEAR);
    assert (writeback_control_o.register_write_enable);
    assert (writeback_control_o.writeback_source == WRITEBACK_SOURCE_CSR);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);
    assert (!instruction_invalid_o);

    // CSRRCI with zimm=0 reads without writing the CSR.
    rs1_i = 5'd0;
    #1ns;
    assert (memory_control_o.read_enable);
    assert (!memory_control_o.write_enable);
    assert (writeback_control_o.register_write_enable);

    // Unknown opcode: no memory or register writes are allowed.
    opcode_i = opcode_t'(7'b1111111);
    #1ns;
    assert (execute_control_o.alu_operation == ALU_INVALID);
    check_memory_disabled();
    assert (!writeback_control_o.register_write_enable);
    assert (writeback_control_o.memory_access_size == MEMORY_ACCESS_INVALID);
    assert (!writeback_control_o.load_unsigned);
    assert (!uses_rs1_o);
    assert (!uses_rs2_o);
    assert (instruction_invalid_o);

    $display("controller tests passed");
    $finish;
  end
endmodule
