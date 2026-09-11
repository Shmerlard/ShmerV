import core_types::*;

module instruction_decoder (
    input logic [31:0] instruction_i,

    output opcode_t opcode_o,
    output logic [4:0] rd_o,
    output logic [2:0] funct3_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output instruction_type_t instruction_type_o,
    output alu_operation_t alu_operation_o
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

  always_comb begin
    alu_operation_o = ALU_INVALID;

    case (opcode_o)
      // R-Type
      OPCODE_REG: begin
        case (funct3_o)
          // ADD and SUB
          3'b000: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_ADD;
              7'b0100000: alu_operation_o = ALU_SUB;
              default:    alu_operation_o = ALU_INVALID;
            endcase
          end

          // SLL
          3'b001: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SLL;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // SLT
          3'b010: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SLT;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // SLTU
          3'b011: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SLTU;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // XOR
          3'b100: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_XOR;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // SRL, SRA
          3'b101: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SRL;
              7'b0100000: alu_operation_o = ALU_SRA;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // OR
          3'b110: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_OR;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end

          // AND
          3'b111: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_AND;
              default: alu_operation_o = ALU_INVALID;
            endcase
          end
          default: alu_operation_o = ALU_INVALID;
        endcase
      end

      // I-Type
      OPCODE_IMM: begin
        case (funct3_o)
          3'b000: alu_operation_o = ALU_ADD;

          3'b001: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SLL;
              default:    alu_operation_o = ALU_INVALID;
            endcase
          end

          3'b010: alu_operation_o = ALU_SLT;
          3'b011: alu_operation_o = ALU_SLTU;
          3'b100: alu_operation_o = ALU_XOR;

          3'b101: begin
            case (funct7_o)
              7'b0000000: alu_operation_o = ALU_SRL;
              7'b0100000: alu_operation_o = ALU_SRA;
              default:    alu_operation_o = ALU_INVALID;
            endcase
          end

          3'b110: alu_operation_o = ALU_OR;
          3'b111: alu_operation_o = ALU_AND;

          default: alu_operation_o = ALU_INVALID;
        endcase
      end


      default: alu_operation_o = ALU_INVALID;
    endcase
  end
endmodule
