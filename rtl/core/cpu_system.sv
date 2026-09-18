timeunit 1ns / 1ps;

module cpu_system #(
    parameter string MEMORY_INIT_FILE = "",
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input logic clk,
    input logic rst
);

  logic [31:0] imem_read_data;
  logic [31:0] imem_read_address;
  logic imem_read_enable;

  logic [31:0] dmem_read_data;
  logic dmem_read_enable;
  logic [31:0] dmem_read_address;
  logic dmem_write_enable;
  logic [3:0] dmem_write_byte_enable;
  logic [31:0] dmem_write_address;
  logic [31:0] dmem_write_data;

  cpu #(
      .RESET_PC(RESET_PC)
  ) cpu (
      .clk                     (clk),
      .rst                     (rst),
      .imem_read_data_i        (imem_read_data),
      .dmem_read_data_i        (dmem_read_data),
      .dmem_write_enable_o     (dmem_write_enable),
      .dmem_write_byte_enable_o(dmem_write_byte_enable),
      .dmem_read_enable_o      (dmem_read_enable),
      .imem_read_enable_o      (imem_read_enable),
      .imem_read_address_o     (imem_read_address),
      .dmem_read_address_o     (dmem_read_address),
      .dmem_write_address_o    (dmem_write_address),
      .dmem_write_data_o       (dmem_write_data)
  );

  memory #(
      .INIT_FILE(MEMORY_INIT_FILE)
  ) memory (
      .clk                       (clk),
      .port_a_read_address_i     (imem_read_address),
      .port_a_read_enable_i      (imem_read_enable),
      .port_a_read_data_o        (imem_read_data),
      .port_b_read_address_i     (dmem_read_address),
      .port_b_write_address_i    (dmem_write_address),
      .port_b_write_enable_i     (dmem_write_enable),
      .port_b_write_byte_enable_i(dmem_write_byte_enable),
      .port_b_read_enable_i      (dmem_read_enable),
      .port_b_write_data_i       (dmem_write_data),
      .port_b_read_data_o        (dmem_read_data)
  );

endmodule
