import core_types::*;

module instruction_decoder (
    input logic [31:0] instruction_i,

    output opcode_t opcode_o,
    output logic [4:0] rd_o,
    output logic [2:0] funct3_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output instruction_type_t instruction_type_o
);


  assign opcode_o = opcode_t'(instruction_i[6:0]);
  assign rd_o     = instruction_i[11:7];
  assign funct3_o = instruction_i[14:12];
  assign rs1_o    = instruction_i[19:15];
  assign rs2_o    = instruction_i[24:20];
  assign funct7_o = instruction_i[31:25];

  always_comb begin
    case (opcode_o)
      OPCODE_REG: instruction_type_o = TYPE_R;

      OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR, OPCODE_SYSTEM: instruction_type_o = TYPE_I;

      OPCODE_STORE: instruction_type_o = TYPE_S;

      OPCODE_BRANCH: instruction_type_o = TYPE_B;

      OPCODE_LUI, OPCODE_AUIPC: instruction_type_o = TYPE_U;

      OPCODE_JAL: instruction_type_o = TYPE_J;

      default: instruction_type_o = TYPE_INVALID;
    endcase
  end

endmodule
