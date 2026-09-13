import core_types::*;

module mem_stage (
    input logic valid_i,
    input logic [31:0] alu_result_i,
    input logic [31:0] rs2_data_i,

    input memory_control_t memory_control_i,

    output logic [31:0] memory_address_o,
    output logic [31:0] memory_write_data_o,

    output logic memory_read_enable_o,
    output logic memory_write_enable_o

);
  assign memory_address_o = alu_result_i;

  assign memory_read_enable_o = memory_control_i.memory_read_enable && valid_i;
  assign memory_write_enable_o = memory_control_i.memory_write_enable && valid_i;

  assign memory_write_data_o = rs2_data_i;

endmodule
