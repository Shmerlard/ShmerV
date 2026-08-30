timeunit 1ns / 1ps;

import core_types::*;

module alu_tb;

  logic [31:0] a;
  logic [31:0] b;
  alu_op_t    op;
  logic [31:0] result;

  alu dut (
      .a(a),
      .b(b),
      .op(op),
      .result(result)
  );

  task automatic check(input logic [31:0] test_a, input logic [31:0] test_b, input alu_op_t test_op,
                       input logic [31:0] expected);
    begin
      a  = test_a;
      b  = test_b;
      op = test_op;

      #1;

      if (result !== expected) begin
        $fatal(1, "FAILED: op=%s a=%h b=%h expected=%h got=%h", test_op.name(), a, b, expected,
               result);
      end
    end
  endtask

  initial begin

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

    // Only b[4:0] controls shift amount.
    // 33 -> shift by 1.
    check(32'h0000_0001, 32'd33, ALU_SLL, 32'h0000_0002);

    $display("All ALU tests passed.");
    $finish;

  end

endmodule
