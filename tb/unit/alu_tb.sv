timeunit 1ns / 1ps;

import core_types::*;

module alu_tb;

  logic [31:0] operand_a_i;
  logic [31:0] operand_b_i;
  alu_operation_t    operation_i;
  logic [31:0] result_o;
  logic equal_o;
  logic signed_less_than_o;
  logic unsigned_less_than_o;

  alu dut (
      .operand_a_i         (operand_a_i),
      .operand_b_i         (operand_b_i),
      .operation_i         (operation_i),
      .result_o            (result_o),
      .equal_o             (equal_o),
      .signed_less_than_o  (signed_less_than_o),
      .unsigned_less_than_o(unsigned_less_than_o)
  );

  task automatic check(input logic [31:0] test_a, input logic [31:0] test_b,
                       input alu_operation_t test_op, input logic [31:0] expected);
    begin
      operand_a_i = test_a;
      operand_b_i = test_b;
      operation_i = test_op;

      #1;

      if (result_o !== expected) begin
        $fatal(1, "FAILED: operation_i=%s operand_a_i=%h operand_b_i=%h expected=%h got=%h",
               test_op.name(), operand_a_i, operand_b_i, expected, result_o);
      end
    end
  endtask

  initial begin
    $dumpfile("build/tests/alu/waveform.fst");
    $dumpvars(0, alu_tb);

    // ADD
    check(32'd10, 32'd20, ALU_ADD, 32'd30);
    check(32'hFFFF_FFFF, 32'd1, ALU_ADD, 32'd0);

    // SUB
    check(32'd20, 32'd10, ALU_SUB, 32'd10);
    check(32'd0, 32'd1, ALU_SUB, 32'hFFFF_FFFF);

    // SLL
    check(32'h0000_0001, 32'd4, ALU_SLL, 32'h0000_0010);
    check(32'h0000_0001, 32'd31, ALU_SLL, 32'h8000_0000);

    // SLT - signed
    check(32'hFFFF_FFFF, 32'd1, ALU_SLT, 32'd1);  // -1 < 1
    check(32'd5, 32'd2, ALU_SLT, 32'd0);

    // SLTU - unsigned
    check(32'hFFFF_FFFF, 32'd1, ALU_SLTU, 32'd0);
    check(32'd1, 32'd2, ALU_SLTU, 32'd1);

    // XOR
    check(32'hAAAA_AAAA, 32'hFFFF_0000, ALU_XOR, 32'h5555_AAAA);

    // SRL
    check(32'h8000_0000, 32'd1, ALU_SRL, 32'h4000_0000);

    // SRA
    check(32'h8000_0000, 32'd1, ALU_SRA, 32'hC000_0000);
    check(32'h4000_0000, 32'd1, ALU_SRA, 32'h2000_0000);

    // OR
    check(32'hAAAA_0000, 32'h0000_5555, ALU_OR, 32'hAAAA_5555);

    // AND
    check(32'hFFFF_0000, 32'hAAAA_AAAA, ALU_AND, 32'hAAAA_0000);

    // Only operand_b_i[4:0] controls shift amount.
    // 33 -> shift by 1.
    check(32'h0000_0001, 32'd33, ALU_SLL, 32'h0000_0002);

    // Comparison status outputs are independent of the selected operation.
    check(32'd5, 32'd5, ALU_ADD, 32'd10);
    assert (equal_o);
    assert (!signed_less_than_o);
    assert (!unsigned_less_than_o);

    check(32'hFFFF_FFFF, 32'd1, ALU_ADD, 32'd0);
    assert (!equal_o);
    assert (signed_less_than_o);
    assert (!unsigned_less_than_o);

    check(32'd1, 32'd2, ALU_ADD, 32'd3);
    assert (!equal_o);
    assert (signed_less_than_o);
    assert (unsigned_less_than_o);

    $display("All ALU tests passed.");
    $finish;

  end

endmodule
