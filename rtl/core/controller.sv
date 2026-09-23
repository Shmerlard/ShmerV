import core_types::*;
import csr_types::*;

module controller (
    input opcode_t opcode_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    input logic [4:0] rd_i,

    output execute_control_t execute_control_o,
    output memory_control_t memory_control_o,
    output writeback_control_t writeback_control_o,
    output logic uses_rs1_o,
    output logic uses_rs2_o,
    output logic instruction_invalid_o
);

  alu_operation_t alu_operation;
  pc_redirect_condition_t branch_condition;
  memory_access_size_t memory_access_size;
  logic load_unsigned;

  logic memory_access_valid;
  logic register_write_enable;
  assign memory_access_valid   = memory_access_size != MEMORY_ACCESS_INVALID;
  assign register_write_enable = (alu_operation != ALU_INVALID) && memory_access_valid;

  // control bits assignment
  always_comb begin
    execute_control_o   = '0;
    memory_control_o    = '0;
    writeback_control_o = '0;
    memory_control_o.access_size = MEMORY_ACCESS_INVALID;
    writeback_control_o.memory_access_size = MEMORY_ACCESS_INVALID;
    execute_control_o.alu_operation = alu_operation;


    instruction_invalid_o = 1'b0;
    case (opcode_i)
      OPCODE_REG: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_RS2;
        writeback_control_o.register_write_enable = alu_operation != ALU_INVALID;
        if (alu_operation == ALU_INVALID) begin
          instruction_invalid_o = 1'b1;
        end
      end

      OPCODE_IMM: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        writeback_control_o.register_write_enable = alu_operation != ALU_INVALID;
        if (alu_operation == ALU_INVALID) begin
          instruction_invalid_o = 1'b1;
        end
      end

      OPCODE_LOAD: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        memory_control_o.read_enable = memory_access_valid;
        memory_control_o.target = MEMORY_TARGET_DMEMORY;
        memory_control_o.access_size = memory_access_size;

        writeback_control_o.register_write_enable = register_write_enable;
        writeback_control_o.writeback_source = WRITEBACK_SOURCE_MEMORY;
        writeback_control_o.memory_access_size = memory_access_size;
        writeback_control_o.load_unsigned = load_unsigned;
        if (!memory_access_valid) begin
          instruction_invalid_o = 1'b1;
        end
      end

      OPCODE_STORE: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        memory_control_o.write_enable = memory_access_valid;
        memory_control_o.target = MEMORY_TARGET_DMEMORY;
        memory_control_o.access_size = memory_access_size;
        execute_control_o.store_data_select = STORE_DATA_FORWARDED_RS2;
        if (!memory_access_valid) begin
          instruction_invalid_o = 1'b1;
        end
      end

      OPCODE_JAL: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_PC;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        execute_control_o.pc_redirect_condition = PC_REDIRECT_ALWAYS;
        execute_control_o.pc_redirect_address_source = PC_REDIRECT_ADDRESS_PC_IMMEDIATE;
        writeback_control_o.register_write_enable = 1'b1;
        writeback_control_o.writeback_source = WRITEBACK_SOURCE_PC4;
      end

      OPCODE_JALR: begin
        if (alu_operation != ALU_INVALID) begin
          execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
          execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
          execute_control_o.pc_redirect_condition = PC_REDIRECT_ALWAYS;
          execute_control_o.pc_redirect_address_source = PC_REDIRECT_ADDRESS_ALU_RESULT;
          execute_control_o.pc_redirect_zero_lsb = 1'b1;
          writeback_control_o.register_write_enable = 1'b1;
          writeback_control_o.writeback_source = WRITEBACK_SOURCE_PC4;
        end else begin
          instruction_invalid_o = 1'b1;
        end
      end

      OPCODE_LUI: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_ZERO;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        writeback_control_o.register_write_enable = 1'b1;
        writeback_control_o.writeback_source = WRITEBACK_SOURCE_ALU;
      end

      OPCODE_AUIPC: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_PC;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        writeback_control_o.register_write_enable = 1'b1;
        writeback_control_o.writeback_source = WRITEBACK_SOURCE_ALU;
      end

      OPCODE_BRANCH: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_RS2;
        execute_control_o.pc_redirect_condition = branch_condition;
        execute_control_o.pc_redirect_address_source = PC_REDIRECT_ADDRESS_PC_IMMEDIATE;
        if (branch_condition == PC_REDIRECT_NEVER) begin
          instruction_invalid_o = 1'b1;
        end
      end

      // TODO: later move all the cases into different block
      OPCODE_SYSTEM: begin
        case (csr_instruction_t'(funct3_i))
          CSR_INSTRUCTION_CSRRW: begin
            execute_control_o.store_data_select = STORE_DATA_FORWARDED_RS1;
            memory_control_o.target = MEMORY_TARGET_CSR;
            memory_control_o.read_enable = rd_i != 5'b0;
            memory_control_o.write_enable = 1'b1;
            writeback_control_o.writeback_source = WRITEBACK_SOURCE_CSR;
            writeback_control_o.register_write_enable = rd_i != 5'b0;
          end
          CSR_INSTRUCTION_CSRRS: begin
            instruction_invalid_o = 1'b1;
          end
          CSR_INSTRUCTION_CSRRC: begin
            instruction_invalid_o = 1'b1;
          end
          CSR_INSTRUCTION_CSRRWI: begin
            instruction_invalid_o = 1'b1;
          end
          CSR_INSTRUCTION_CSRRSI: begin
            instruction_invalid_o = 1'b1;
          end
          CSR_INSTRUCTION_CSRRCI: begin
            instruction_invalid_o = 1'b1;
          end
          default: begin
            instruction_invalid_o = 1'b1;
          end
        endcase
      end

      default: begin
        instruction_invalid_o = 1'b1;
      end
    endcase
  end

  // alu operation assignment
  always_comb begin
    alu_operation = ALU_INVALID;

    case (opcode_i)
      OPCODE_REG: begin
        case (funct7_i)
          7'b0000000: begin
            case (funct3_i)
              3'b000:  alu_operation = ALU_ADD;
              3'b001:  alu_operation = ALU_SLL;
              3'b010:  alu_operation = ALU_SLT;
              3'b011:  alu_operation = ALU_SLTU;
              3'b100:  alu_operation = ALU_XOR;
              3'b101:  alu_operation = ALU_SRL;
              3'b110:  alu_operation = ALU_OR;
              3'b111:  alu_operation = ALU_AND;
              default: alu_operation = ALU_INVALID;
            endcase
          end

          7'b0100000: begin
            case (funct3_i)
              3'b000:  alu_operation = ALU_SUB;
              3'b101:  alu_operation = ALU_SRA;
              default: alu_operation = ALU_INVALID;
            endcase
          end

          default: alu_operation = ALU_INVALID;
        endcase
      end

      OPCODE_IMM: begin
        case (funct3_i)
          3'b000:  alu_operation = ALU_ADD;
          3'b001: begin
            if (funct7_i == 7'b0000000) alu_operation = ALU_SLL;
          end
          3'b010:  alu_operation = ALU_SLT;
          3'b011:  alu_operation = ALU_SLTU;
          3'b100:  alu_operation = ALU_XOR;
          3'b101: begin
            case (funct7_i)
              7'b0000000: alu_operation = ALU_SRL;
              7'b0100000: alu_operation = ALU_SRA;
              default:    alu_operation = ALU_INVALID;
            endcase
          end
          3'b110:  alu_operation = ALU_OR;
          3'b111:  alu_operation = ALU_AND;
          default: alu_operation = ALU_INVALID;
        endcase
      end

      OPCODE_LOAD, OPCODE_STORE: alu_operation = ALU_ADD;

      OPCODE_JAL: alu_operation = ALU_ADD;

      OPCODE_JALR: begin
        if (funct3_i == 3'b000) alu_operation = ALU_ADD;
      end

      OPCODE_LUI, OPCODE_AUIPC: begin
        alu_operation = ALU_ADD;
      end

      OPCODE_BRANCH: begin
        if (branch_condition != PC_REDIRECT_NEVER) alu_operation = ALU_SUB;
      end

      default: alu_operation = ALU_INVALID;
    endcase
  end

  // branch condition assignment
  always_comb begin
    branch_condition = PC_REDIRECT_NEVER;

    if (opcode_i == OPCODE_BRANCH) begin
      case (funct3_i)
        3'b000:  branch_condition = PC_REDIRECT_EQ;
        3'b001:  branch_condition = PC_REDIRECT_NEQ;
        3'b100:  branch_condition = PC_REDIRECT_LT;
        3'b101:  branch_condition = PC_REDIRECT_GE;
        3'b110:  branch_condition = PC_REDIRECT_ULT;
        3'b111:  branch_condition = PC_REDIRECT_UGE;
        default: branch_condition = PC_REDIRECT_NEVER;
      endcase
    end
  end

  // uses rs1, rs2 assignment
  always_comb begin
    uses_rs1_o = 1'b0;
    uses_rs2_o = 1'b0;

    case (opcode_i)
      OPCODE_REG, OPCODE_STORE, OPCODE_BRANCH: begin
        uses_rs1_o = 1'b1;
        uses_rs2_o = 1'b1;
      end

      OPCODE_IMM, OPCODE_LOAD, OPCODE_JALR: begin
        uses_rs1_o = 1'b1;
      end

      OPCODE_SYSTEM: begin
        case (csr_instruction_t'(funct3_i))
          CSR_INSTRUCTION_CSRRW: uses_rs1_o = 1'b1;
          CSR_INSTRUCTION_CSRRS: uses_rs1_o = 1'b1;
          CSR_INSTRUCTION_CSRRC: uses_rs1_o = 1'b1;

          CSR_INSTRUCTION_CSRRWI: uses_rs1_o = 1'b0;
          CSR_INSTRUCTION_CSRRSI: uses_rs1_o = 1'b0;
          CSR_INSTRUCTION_CSRRCI: uses_rs1_o = 1'b0;

          default: uses_rs1_o = 1'b0;
        endcase
      end

      default: begin
      end
    endcase
  end

  // Memory access size signal assignment
  always_comb begin
    memory_access_size = MEMORY_ACCESS_INVALID;
    load_unsigned = 1'b0;
    case (opcode_i)
      OPCODE_LOAD: begin
        case (funct3_i)
          3'b000:  memory_access_size = MEMORY_ACCESS_BYTE;
          3'b001:  memory_access_size = MEMORY_ACCESS_HALF;
          3'b010:  memory_access_size = MEMORY_ACCESS_WORD;
          3'b100: begin
            memory_access_size = MEMORY_ACCESS_BYTE;
            load_unsigned = 1'b1;
          end
          3'b101: begin
            memory_access_size = MEMORY_ACCESS_HALF;
            load_unsigned = 1'b1;
          end
          default: memory_access_size = MEMORY_ACCESS_INVALID;
        endcase
      end
      OPCODE_STORE: begin
        case (funct3_i)
          3'b000:  memory_access_size = MEMORY_ACCESS_BYTE;
          3'b001:  memory_access_size = MEMORY_ACCESS_HALF;
          3'b010:  memory_access_size = MEMORY_ACCESS_WORD;
          default: memory_access_size = MEMORY_ACCESS_INVALID;
        endcase
      end
      OPCODE_IMM: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_AUIPC: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_REG: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_LUI: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_BRANCH: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_JALR: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_JAL: memory_access_size = MEMORY_ACCESS_INVALID;
      OPCODE_SYSTEM: memory_access_size = MEMORY_ACCESS_INVALID;
      // OPCODE
      default: memory_access_size = MEMORY_ACCESS_INVALID;
    endcase
  end



endmodule
