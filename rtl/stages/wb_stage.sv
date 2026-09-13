import core_types::*;
module wb_stage (
    input logic valid_i,
    input writeback_control_t writeback_control_i,
    input [31:0] alu_result_i,
    input [31:0] memory_read_data_i,
    output [31:0] writeback_data_o,
    output logic rf_write_enable_o

);

  logic wb_source;
  assign wb_source = writeback_control_i.writeback_source;

  assign writeback_data_o = wb_source ? memory_read_data_i : alu_result_i;
  assign rf_write_enable_o = writeback_control_i.register_write_enable && valid_i;

endmodule
