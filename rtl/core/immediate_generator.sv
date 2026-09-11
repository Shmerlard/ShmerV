import core_types::*;

module immediate_generator (
    input logic [31:0] instruction_i,
    input instruction_type_t instruction_type_i,

    output logic [31:0] immediate_o
);

  always_comb begin
    case (instruction_type_i)

      TYPE_I: begin
        immediate_o = {{20{instruction_i[31]}}, instruction_i[31:20]};
      end

      TYPE_S: begin
        immediate_o = {{20{instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
      end

      TYPE_B: begin
        immediate_o = {
          {19{instruction_i[31]}},
          instruction_i[31],
          instruction_i[7],
          instruction_i[30:25],
          instruction_i[11:8],
          1'b0
        };
      end

      TYPE_U: begin
        immediate_o = {instruction_i[31:12], 12'b0};
      end

      TYPE_J: begin
        immediate_o = {
          {11{instruction_i[31]}},
          instruction_i[31],
          instruction_i[19:12],
          instruction_i[20],
          instruction_i[30:21],
          1'b0
        };
      end

      TYPE_R, TYPE_INVALID: begin
        immediate_o = '0;
      end

      default: immediate_o = '0;

    endcase
  end

endmodule
