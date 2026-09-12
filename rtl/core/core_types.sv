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
    ALU_AND,
    ALU_INVALID
  } alu_operation_t;

  typedef enum logic [1:0] {
    ALU_OPERAND_A_RS1,
    ALU_OPERAND_A_ZERO,
    ALU_OPERAND_A_PC
  } alu_operand_a_select_t;

  typedef enum logic {
    ALU_OPERAND_B_RS2,
    ALU_OPERAND_B_IMM
  } alu_operand_b_select_t;


  typedef enum logic [2:0] {
    TYPE_R,
    TYPE_I,
    TYPE_S,
    TYPE_B,
    TYPE_U,
    TYPE_J,
    TYPE_INVALID
  } instruction_type_t;

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

  typedef struct packed {
    alu_operand_a_select_t alu_operand_a_select;
    alu_operand_b_select_t alu_operand_b_select;
    alu_operation_t alu_operation;
  } execute_control_t;

  typedef struct packed {
    logic memory_read_enable;
    logic memory_write_enable;
  } memory_control_t;

  typedef struct packed {
    logic register_write_enable;
    logic writeback_source;  // 0: alu result, 1: memory read data // TODO: maybe make an ENUM?
  } writeback_control_t;


endpackage
