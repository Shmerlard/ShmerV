timeunit 1ns / 1ps;

import core_types::*;

module immediate_generator_tb;

  logic [31:0] instruction_i;
  instruction_type_t instruction_type_i;
  logic [31:0] immediate_o;

  immediate_generator dut (
      .instruction_i(instruction_i),
      .instruction_type_i(instruction_type_i),
      .immediate_o(immediate_o)
  );

  task automatic check(input logic [31:0] test_instr, input instruction_type_t test_type,
                       input logic [31:0] expected);
    begin
      instruction_i      = test_instr;
      instruction_type_i = test_type;

      #1;

      if (immediate_o !== expected) begin
        $error("FAILED: type=%s instruction_i=%h expected=%h got=%h", test_type.name(),
               instruction_i, expected, immediate_o);
      end
    end
  endtask

  initial begin
    $dumpfile("build/tests/immediate_generator/waveform.fst");
    $dumpvars(0, immediate_generator_tb);

    // I-type: +10
    check(32'b000000001010_00001_000_00011_0010011, TYPE_I, 32'd10);

    // I-type: -1
    check(32'b111111111111_00001_000_00011_0010011, TYPE_I, 32'hFFFF_FFFF);

    // S-type: offset 8
    check(32'b0000000_00010_00001_010_01000_0100011, TYPE_S, 32'd8);

    // S-type: offset -4
    check(32'b1111111_00010_00001_010_11100_0100011, TYPE_S, 32'hFFFF_FFFC);

    // B-type: offset 8
    check(32'b0000000_00010_00001_000_01000_1100011, TYPE_B, 32'd8);

    // U-type
    check(32'b00010010001101000101_00011_0110111, TYPE_U, 32'h1234_5000);

    // J-type: offset 2
    check(32'b00000000001000000000_00011_1101111, TYPE_J, 32'd2);

    // R-type has no immediate
    check(32'b0000000_00010_00001_000_00011_0110011, TYPE_R, 32'd0);

    // Invalid type
    check(32'd0, TYPE_INVALID, 32'd0);

    $display("immediate_generator tests passed");
    $finish;
  end

endmodule
