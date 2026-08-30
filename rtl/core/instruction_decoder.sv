import core_types::*;

module instruction_decoder (
    input logic [31:0] instr,

    output opcode_t opcode,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] funct7,
    output instr_type_t instr_type,
    output alu_op_t alu_op
);


  assign opcode = opcode_t'(instr[6:0]);
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];

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

  always_comb begin
    alu_op = ALU_INVALID;

    case (opcode)
      // R-Type
      OPCODE_REG: begin
        case (funct3)
          // ADD and SUB
          3'b000: begin
            case (funct7)
              7'b0000000: alu_op = ALU_ADD;
              7'b0100000: alu_op = ALU_SUB;
              default:    alu_op = ALU_INVALID;
            endcase
          end

          // SLL
          3'b001: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SLL;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // SLT
          3'b010: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SLT;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // SLTU
          3'b011: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SLTU;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // XOR
          3'b100: begin
            case (funct7)
              7'b0000000: alu_op = ALU_XOR;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // SRL, SRA
          3'b101: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SRL;
              7'b0100000: alu_op = ALU_SRA;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // OR
          3'b110: begin
            case (funct7)
              7'b0000000: alu_op = ALU_OR;
              default: alu_op = ALU_INVALID;
            endcase
          end

          // AND
          3'b111: begin
            case (funct7)
              7'b0000000: alu_op = ALU_AND;
              default: alu_op = ALU_INVALID;
            endcase
          end
          default: alu_op = ALU_INVALID;
        endcase
      end

      // I-Type
      OPCODE_IMM: begin
        case (funct3)
          3'b000: alu_op = ALU_ADD;

          3'b001: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SLL;
              default:    alu_op = ALU_INVALID;
            endcase
          end

          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;

          3'b101: begin
            case (funct7)
              7'b0000000: alu_op = ALU_SRL;
              7'b0100000: alu_op = ALU_SRA;
              default:    alu_op = ALU_INVALID;
            endcase
          end

          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;

          default: alu_op = ALU_INVALID;
        endcase
      end


      default: alu_op = ALU_INVALID;
    endcase
  end
endmodule
