timeunit 1ns / 1ps;

import core_types::*;

module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_op_t op,
    output logic [31:0] result
);

  always_comb begin
    case (op)
      ALU_ADD:  result = a + b;
      ALU_SUB:  result = a - b;
      ALU_SLL:  result = a << b[4:0];
      ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : '0;
      ALU_SLTU: result = (a < b) ? 32'd1 : '0;
      ALU_XOR:  result = a ^ b;
      ALU_SRL:  result = a >> b[4:0];
      ALU_SRA:  result = $unsigned($signed(a) >>> b[4:0]);
      ALU_OR:   result = a | b;
      ALU_AND:  result = a & b;
      default:  result = '0;
    endcase
  end
endmodule
