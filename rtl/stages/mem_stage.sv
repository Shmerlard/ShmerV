import core_types::*;

module mem_stage (
    input logic [31:0] alu_result_i,
    input logic [ 4:0] rd_i,
    input logic [31:0] rs2_data_i,

    input logic [31:0] memory_read_data_i,

    input memory_control_t memory_control_i,
    input writeback_control_t writeback_control_i,
    output writeback_control_t writeback_control_o,

    output logic [31:0] memory_address_o,
    output logic [31:0] memory_write_data_o,

    output logic memory_read_enable_o,
    output logic memory_write_enable_o,
    output logic [31:0] alu_result_o,
    output logic [31:0] memory_read_data_o,


    output logic [4:0] rd_o


);

  assign writeback_control_o = writeback_control_i;
  assign alu_result_o = alu_result_i;
  assign memory_address_o = alu_result_i;

  assign memory_read_enable_o = memory_control_i.memory_read_enable;
  assign memory_write_enable_o = memory_control_i.memory_write_enable;

  assign rd_o = rd_i;
  assign memory_read_data_o = memory_read_data_i;
  assign memory_write_data_o = rs2_data_i;

endmodule
