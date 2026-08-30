import core_types::*;

module instruction_decoder (
    input logic [31:0] instr,

    output opcode_t opcode,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] funct7,
    output instr_type_t instr_type
);


  always_comb begin
    case (opcode)
      OPCODE_REG: instr_type = TYPE_R;

      OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR, OPCODE_SYSTEM: instr_type = TYPE_I;

      OPCODE_STORE: instr_type = TYPE_S;

      OPCODE_BRANCH: instr_type = TYPE_B;

      OPCODE_LUI, OPCODE_AUIPC: instr_type = TYPE_U;

      OPCODE_JAL: instr_type = TYPE_J;

      default: instr_type = TYPE_INVALID;
    endcase
  end

  assign opcode = opcode_t'(instr[6:0]);
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];

endmodule
