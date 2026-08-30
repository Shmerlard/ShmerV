timeunit 1ns / 1ps;

import core_types::*;

module instruction_decoder_tb;

  logic [31:0] instr;

  opcode_t    opcode;
  logic [4:0] rd;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [6:0] funct7;
  instr_type_t instr_type;

  instruction_decoder dut (
      .instr(instr),
      .opcode(opcode),
      .rd(rd),
      .funct3(funct3),
      .rs1(rs1),
      .rs2(rs2),
      .funct7(funct7),
      .instr_type(instr_type)
  );

  initial begin

    // R-type
    // funct7=0100000, rs2=2, rs1=1, funct3=000, rd=3, opcode=0110011
    instr = 32'b0100000_00010_00001_000_00011_0110011;
    #1;

    assert (opcode == OPCODE_REG);
    assert (instr_type == TYPE_R);
    assert (rd == 5'd3);
    assert (rs1 == 5'd1);
    assert (rs2 == 5'd2);
    assert (funct3 == 3'b000);
    assert (funct7 == 7'b0100000);

    // I-type
    instr = 32'b000000001010_00001_000_00011_0010011;
    #1;

    assert (opcode == OPCODE_IMM);
    assert (instr_type == TYPE_I);
    assert (rd == 5'd3);
    assert (rs1 == 5'd1);
    assert (funct3 == 3'b000);

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
