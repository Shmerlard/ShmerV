timeunit 1ns / 1ps;

import core_types::*;

module alu (
    input logic [31:0] operand_a_i,
    input logic [31:0] operand_b_i,
    input alu_operation_t operation_i,
    output logic [31:0] result_o
);

  always_comb begin
    case (operation_i)
      ALU_ADD:  result_o = operand_a_i + operand_b_i;
      ALU_SUB:  result_o = operand_a_i - operand_b_i;
      ALU_SLL:  result_o = operand_a_i << operand_b_i[4:0];
      ALU_SLT:  result_o = ($signed(operand_a_i) < $signed(operand_b_i)) ? 32'd1 : '0;
      ALU_SLTU: result_o = (operand_a_i < operand_b_i) ? 32'd1 : '0;
      ALU_XOR:  result_o = operand_a_i ^ operand_b_i;
      ALU_SRL:  result_o = operand_a_i >> operand_b_i[4:0];
      ALU_SRA:  result_o = $unsigned($signed(operand_a_i) >>> operand_b_i[4:0]);
      ALU_OR:   result_o = operand_a_i | operand_b_i;
      ALU_AND:  result_o = operand_a_i & operand_b_i;
      default:  result_o = '0;
    endcase
  end
endmodule
