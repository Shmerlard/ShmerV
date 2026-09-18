import core_types::*;
module wb_stage (
    input logic valid_i,
    input writeback_control_t writeback_control_i,
    input logic [31:0] alu_result_i,
    input logic [31:0] memory_read_data_i,
    input logic [31:0] pc_plus_4_i,
    output logic [31:0] writeback_data_o,
    output logic rf_write_enable_o

);

  writeback_source_t wb_source;
  logic [31:0] shifted_memory_read_data;
  logic [31:0] formatted_memory_read_data;

  assign wb_source = writeback_control_i.writeback_source;
  assign shifted_memory_read_data = memory_read_data_i >> {alu_result_i[1:0], 3'b000};

  assign rf_write_enable_o = writeback_control_i.register_write_enable && valid_i;

  always_comb begin
    formatted_memory_read_data = memory_read_data_i;

    case (writeback_control_i.memory_access_size)
      MEMORY_ACCESS_BYTE: begin
        if (writeback_control_i.load_unsigned) begin
          formatted_memory_read_data = {24'b0, shifted_memory_read_data[7:0]};
        end else begin
          formatted_memory_read_data = {
            {24{shifted_memory_read_data[7]}}, shifted_memory_read_data[7:0]
          };
        end
      end
      MEMORY_ACCESS_HALF: begin
        if (writeback_control_i.load_unsigned) begin
          formatted_memory_read_data = {16'b0, shifted_memory_read_data[15:0]};
        end else begin
          formatted_memory_read_data = {
            {16{shifted_memory_read_data[15]}}, shifted_memory_read_data[15:0]
          };
        end
      end
      MEMORY_ACCESS_WORD, MEMORY_ACCESS_INVALID: begin
      end
      default: begin
      end
    endcase
  end

  always_comb begin
    writeback_data_o = 32'b0;
    case (wb_source)
      WRITEBACK_SOURCE_ALU: begin
        writeback_data_o = alu_result_i;
      end
      WRITEBACK_SOURCE_MEMORY: begin
        writeback_data_o = formatted_memory_read_data;
      end
      WRITEBACK_SOURCE_PC4: begin
        writeback_data_o = pc_plus_4_i;
      end
      default: begin
        writeback_data_o = 32'b0;
      end
    endcase
  end

endmodule
