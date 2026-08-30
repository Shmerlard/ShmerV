import core_types::*;

module immediate_generator (
    input logic [31:0] instr,
    input instr_type_t instr_type,

    output logic [31:0] imm
);

  always_comb begin
    case (instr_type)

      TYPE_I: begin
        imm = {{20{instr[31]}}, instr[31:20]};
      end

      TYPE_S: begin
        imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end

      TYPE_B: begin
        imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      end

      TYPE_U: begin
        imm = {instr[31:12], 12'b0};
      end

      TYPE_J: begin
        imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      end

      TYPE_R, TYPE_INVALID: begin
        imm = '0;
      end

      default: imm = '0;

    endcase
  end

endmodule
