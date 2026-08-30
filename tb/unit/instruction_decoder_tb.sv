timeunit 1ns / 1ps;

import core_types::*;

module instruction_decoder_tb;

  logic        [31:0] instr;

  opcode_t            opcode;
  logic        [ 4:0] rd;
  logic        [ 2:0] funct3;
  logic        [ 4:0] rs1;
  logic        [ 4:0] rs2;
  logic        [ 6:0] funct7;
  instr_type_t        instr_type;
  alu_op_t            alu_op;

  instruction_decoder dut (
      .instr(instr),
      .opcode(opcode),
      .rd(rd),
      .funct3(funct3),
      .rs1(rs1),
      .rs2(rs2),
      .funct7(funct7),
      .instr_type(instr_type),
      .alu_op(alu_op)
  );

  initial begin
    $dumpfile("build/instruction_decoder.fst");
    $dumpvars(0, instruction_decoder_tb);
    // R-type: ADD
    instr = 32'b0000000_00010_00001_000_00011_0110011;
    #1;

    assert (opcode == OPCODE_REG);
    assert (instr_type == TYPE_R);
    assert (rd == 5'd3);
    assert (rs1 == 5'd1);
    assert (rs2 == 5'd2);
    assert (funct3 == 3'b000);
    assert (funct7 == 7'b0000000);
    assert (alu_op == ALU_ADD);

    // R-type: SUB
    instr = 32'b0100000_00010_00001_000_00011_0110011;
    #1;
    assert (alu_op == ALU_SUB);

    // R-type: SLL
    instr = 32'b0000000_00010_00001_001_00011_0110011;
    #1;
    assert (alu_op == ALU_SLL);

    // R-type: SLT
    instr = 32'b0000000_00010_00001_010_00011_0110011;
    #1;
    assert (alu_op == ALU_SLT);

    // R-type: SLTU
    instr = 32'b0000000_00010_00001_011_00011_0110011;
    #1;
    assert (alu_op == ALU_SLTU);

    // R-type: XOR
    instr = 32'b0000000_00010_00001_100_00011_0110011;
    #1;
    assert (alu_op == ALU_XOR);

    // R-type: SRL
    instr = 32'b0000000_00010_00001_101_00011_0110011;
    #1;
    assert (alu_op == ALU_SRL);

    // R-type: SRA
    instr = 32'b0100000_00010_00001_101_00011_0110011;
    #1;
    assert (alu_op == ALU_SRA);

    // R-type: OR
    instr = 32'b0000000_00010_00001_110_00011_0110011;
    #1;
    assert (alu_op == ALU_OR);

    // R-type: AND
    instr = 32'b0000000_00010_00001_111_00011_0110011;
    #1;
    assert (alu_op == ALU_AND);

    // Invalid R-type encoding
    instr = 32'b1111111_00010_00001_000_00011_0110011;
    #1;
    assert (alu_op == ALU_INVALID);

    // I-type: ADDI
    instr = 32'b000000001010_00001_000_00011_0010011;
    #1;

    assert (opcode == OPCODE_IMM);
    assert (instr_type == TYPE_I);
    assert (rd == 5'd3);
    assert (rs1 == 5'd1);
    assert (funct3 == 3'b000);
    assert (alu_op == ALU_ADD);

    // I-type: SLLI
    instr = 32'b0000000_00010_00001_001_00011_0010011;
    #1;
    assert (alu_op == ALU_SLL);

    // I-type: SLTI
    instr = 32'b000000000010_00001_010_00011_0010011;
    #1;
    assert (alu_op == ALU_SLT);

    // I-type: SLTIU
    instr = 32'b000000000010_00001_011_00011_0010011;
    #1;
    assert (alu_op == ALU_SLTU);

    // I-type: XORI
    instr = 32'b000000000010_00001_100_00011_0010011;
    #1;
    assert (alu_op == ALU_XOR);

    // I-type: SRLI
    instr = 32'b0000000_00010_00001_101_00011_0010011;
    #1;
    assert (alu_op == ALU_SRL);

    // I-type: SRAI
    instr = 32'b0100000_00010_00001_101_00011_0010011;
    #1;
    assert (alu_op == ALU_SRA);

    // I-type: ORI
    instr = 32'b000000000010_00001_110_00011_0010011;
    #1;
    assert (alu_op == ALU_OR);

    // I-type: ANDI
    instr = 32'b000000000010_00001_111_00011_0010011;
    #1;
    assert (alu_op == ALU_AND);

    // Invalid I-type shift encodings
    instr = 32'b1111111_00010_00001_001_00011_0010011;
    #1;
    assert (alu_op == ALU_INVALID);

    instr = 32'b1111111_00010_00001_101_00011_0010011;
    #1;
    assert (alu_op == ALU_INVALID);

    // S-type
    instr = 32'b0000000_00010_00001_010_01000_0100011;
    #1;

    assert (opcode == OPCODE_STORE);
    assert (instr_type == TYPE_S);
    assert (rs1 == 5'd1);
    assert (rs2 == 5'd2);

    // B-type
    instr = 32'b0000000_00010_00001_000_01000_1100011;
    #1;

    assert (opcode == OPCODE_BRANCH);
    assert (instr_type == TYPE_B);

    // U-type
    instr = 32'b00010010001101000101_00011_0110111;
    #1;

    assert (opcode == OPCODE_LUI);
    assert (instr_type == TYPE_U);
    assert (rd == 5'd3);

    // J-type
    instr = 32'b00000000000000000001_00011_1101111;
    #1;

    assert (opcode == OPCODE_JAL);
    assert (instr_type == TYPE_J);
    assert (rd == 5'd3);

    $display("instruction_decoder tests passed");
    $finish;
  end

endmodule
