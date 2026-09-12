import core_types::*;

module controller (
    input opcode_t opcode_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,

    output execute_control_t execute_control_o,
    output memory_control_t memory_control_o,
    output writeback_control_t writeback_control_o
);

  alu_operation_t alu_operation;

  always_comb begin
    execute_control_o   = '0;
    memory_control_o    = '0;
    writeback_control_o = '0;

    execute_control_o.alu_operation = alu_operation;

    case (opcode_i)
      OPCODE_REG: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_RS2;
        writeback_control_o.register_write_enable = alu_operation != ALU_INVALID;
      end

      OPCODE_IMM: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        writeback_control_o.register_write_enable = alu_operation != ALU_INVALID;
      end

      OPCODE_LOAD: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        memory_control_o.memory_read_enable = 1'b1;
        writeback_control_o.register_write_enable = alu_operation != ALU_INVALID;
        writeback_control_o.writeback_source = 1'b1;
      end

      OPCODE_STORE: begin
        execute_control_o.alu_operand_a_select = ALU_OPERAND_A_RS1;
        execute_control_o.alu_operand_b_select = ALU_OPERAND_B_IMM;
        memory_control_o.memory_write_enable   = 1'b1;
      end

      default: begin
      end
    endcase
  end
  always_comb begin
    alu_operation = ALU_INVALID;

    case (opcode_i)
      OPCODE_REG: begin
        case (funct3_i)
          3'b000: begin
            case (funct7_i)
              7'b0000000: alu_operation = ALU_ADD;
              7'b0100000: alu_operation = ALU_SUB;
              default:    alu_operation = ALU_INVALID;
            endcase
          end
          3'b001:  alu_operation = ALU_SLL;
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

      default: alu_operation = ALU_INVALID;
    endcase
  end


endmodule
