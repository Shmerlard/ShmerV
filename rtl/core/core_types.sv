package core_types;

  typedef enum logic [3:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_SLL,
    ALU_SLT,
    ALU_SLTU,
    ALU_XOR,
    ALU_SRL,
    ALU_SRA,
    ALU_OR,
    ALU_AND
  } alu_op_t;

  typedef enum logic [2:0] {
    TYPE_R,
    TYPE_I,
    TYPE_S,
    TYPE_B,
    TYPE_U,
    TYPE_J,
    TYPE_INVALID
  } instr_type_t;

  typedef enum logic [6:0] {
    OPCODE_LOAD   = 7'b0000011,
    OPCODE_IMM    = 7'b0010011,
    OPCODE_AUIPC  = 7'b0010111,
    OPCODE_STORE  = 7'b0100011,
    OPCODE_REG    = 7'b0110011,
    OPCODE_LUI    = 7'b0110111,
    OPCODE_BRANCH = 7'b1100011,
    OPCODE_JALR   = 7'b1100111,
    OPCODE_JAL    = 7'b1101111,
    OPCODE_SYSTEM = 7'b1110011
  } opcode_t;
endpackage
