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

  typedef enum logic [1:0] {
    WRITEBACK_SOURCE_ALU,
    WRITEBACK_SOURCE_MEMORY,
    WRITEBACK_SOURCE_PC4
  } writeback_source_t;

  typedef enum logic [1:0] {
    FORWARD_SOURCE_REGISTER,
    FORWARD_SOURCE_MEM,
    FORWARD_SOURCE_WB
  } forwarding_source_t;

  typedef enum logic [2:0] {
    PC_REDIRECT_NEVER  = 3'b000,
    PC_REDIRECT_EQ     = 3'b001,
    PC_REDIRECT_NEQ    = 3'b010,
    PC_REDIRECT_LT     = 3'b011,
    PC_REDIRECT_GE     = 3'b100,
    PC_REDIRECT_ULT    = 3'b101,
    PC_REDIRECT_UGE    = 3'b110,
    PC_REDIRECT_ALWAYS = 3'b111
  } pc_redirect_condition_t;

  typedef enum logic {
    PC_REDIRECT_ADDRESS_PC_IMMEDIATE,
    PC_REDIRECT_ADDRESS_ALU_RESULT
  } pc_redirect_address_source_t;

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
    pc_redirect_condition_t pc_redirect_condition;
    pc_redirect_address_source_t pc_redirect_address_source;
    logic pc_redirect_zero_lsb;
  } execute_control_t;

  typedef struct packed {
    logic memory_read_enable;
    logic memory_write_enable;
  } memory_control_t;

  typedef struct packed {
    logic register_write_enable;
    writeback_source_t writeback_source;
  } writeback_control_t;


endpackage
