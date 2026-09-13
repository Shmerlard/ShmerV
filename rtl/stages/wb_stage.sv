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
  assign wb_source = writeback_control_i.writeback_source;

  assign rf_write_enable_o = writeback_control_i.register_write_enable && valid_i;

  always_comb begin
    writeback_data_o = 32'b0;
    case (wb_source)
      WRITEBACK_SOURCE_ALU: begin
        writeback_data_o = alu_result_i;
      end
      WRITEBACK_SOURCE_MEMORY: begin
        writeback_data_o = memory_read_data_i;
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
