timeunit 1ns / 1ps;

import core_types::*;

module instruction_decoder_tb;

  logic              [31:0] instruction_i;

  opcode_t                  opcode_o;
  logic              [ 4:0] rd_o;
  logic              [ 2:0] funct3_o;
  logic              [ 4:0] rs1_o;
  logic              [ 4:0] rs2_o;
  logic              [ 6:0] funct7_o;
  instruction_type_t        instruction_type_o;

  instruction_decoder dut (
      .instruction_i(instruction_i),
      .opcode_o(opcode_o),
      .rd_o(rd_o),
      .funct3_o(funct3_o),
      .rs1_o(rs1_o),
      .rs2_o(rs2_o),
      .funct7_o(funct7_o),
      .instruction_type_o(instruction_type_o)
  );

  initial begin
    $dumpfile("build/tests/instruction_decoder/waveform.fst");
    $dumpvars(0, instruction_decoder_tb);
    // R-type: ADD
    instruction_i = 32'b0000000_00010_00001_000_00011_0110011;
    #1;

    assert (opcode_o == OPCODE_REG);
    assert (instruction_type_o == TYPE_R);
    assert (rd_o == 5'd3);
    assert (rs1_o == 5'd1);
    assert (rs2_o == 5'd2);
    assert (funct3_o == 3'b000);
    assert (funct7_o == 7'b0000000);

    // R-type: SUB
    instruction_i = 32'b0100000_00010_00001_000_00011_0110011;
    #1;

    // R-type: SLL
    instruction_i = 32'b0000000_00010_00001_001_00011_0110011;
    #1;

    // R-type: SLT
    instruction_i = 32'b0000000_00010_00001_010_00011_0110011;
    #1;

    // R-type: SLTU
    instruction_i = 32'b0000000_00010_00001_011_00011_0110011;
    #1;

    // R-type: XOR
    instruction_i = 32'b0000000_00010_00001_100_00011_0110011;
    #1;

    // R-type: SRL
    instruction_i = 32'b0000000_00010_00001_101_00011_0110011;
    #1;

    // R-type: SRA
    instruction_i = 32'b0100000_00010_00001_101_00011_0110011;
    #1;

    // R-type: OR
    instruction_i = 32'b0000000_00010_00001_110_00011_0110011;
    #1;

    // R-type: AND
    instruction_i = 32'b0000000_00010_00001_111_00011_0110011;
    #1;

    // Invalid R-type encoding
    instruction_i = 32'b1111111_00010_00001_000_00011_0110011;
    #1;

    // I-type: ADDI
    instruction_i = 32'b000000001010_00001_000_00011_0010011;
    #1;

    assert (opcode_o == OPCODE_IMM);
    assert (instruction_type_o == TYPE_I);
    assert (rd_o == 5'd3);
    assert (rs1_o == 5'd1);
    assert (funct3_o == 3'b000);

    // I-type: SLLI
    instruction_i = 32'b0000000_00010_00001_001_00011_0010011;
    #1;

    // I-type: SLTI
    instruction_i = 32'b000000000010_00001_010_00011_0010011;
    #1;

    // I-type: SLTIU
    instruction_i = 32'b000000000010_00001_011_00011_0010011;
    #1;

    // I-type: XORI
    instruction_i = 32'b000000000010_00001_100_00011_0010011;
    #1;

    // I-type: SRLI
    instruction_i = 32'b0000000_00010_00001_101_00011_0010011;
    #1;

    // I-type: SRAI
    instruction_i = 32'b0100000_00010_00001_101_00011_0010011;
    #1;

    // I-type: ORI
    instruction_i = 32'b000000000010_00001_110_00011_0010011;
    #1;

    // I-type: ANDI
    instruction_i = 32'b000000000010_00001_111_00011_0010011;
    #1;

    // Invalid I-type shift encodings
    instruction_i = 32'b1111111_00010_00001_001_00011_0010011;
    #1;

    instruction_i = 32'b1111111_00010_00001_101_00011_0010011;
    #1;

    // S-type
    instruction_i = 32'b0000000_00010_00001_010_01000_0100011;
    #1;

    assert (opcode_o == OPCODE_STORE);
    assert (instruction_type_o == TYPE_S);
    assert (rs1_o == 5'd1);
    assert (rs2_o == 5'd2);

    // B-type
    instruction_i = 32'b0000000_00010_00001_000_01000_1100011;
    #1;

    assert (opcode_o == OPCODE_BRANCH);
    assert (instruction_type_o == TYPE_B);

    // U-type
    instruction_i = 32'b00010010001101000101_00011_0110111;
    #1;

    assert (opcode_o == OPCODE_LUI);
    assert (instruction_type_o == TYPE_U);
    assert (rd_o == 5'd3);

    // J-type
    instruction_i = 32'b00000000000000000001_00011_1101111;
    #1;

    assert (opcode_o == OPCODE_JAL);
    assert (instruction_type_o == TYPE_J);
    assert (rd_o == 5'd3);

    $display("instruction_decoder tests passed");
    $finish;
  end

endmodule
