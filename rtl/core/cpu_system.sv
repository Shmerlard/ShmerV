timeunit 1ns / 1ps;

module cpu_system #(
    parameter int MEM_WORDS = 1024,
    parameter string MEMORY_INIT_FILE = "",
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input logic clk,
    input logic rst
);

  logic [31:0] imem_load_data;
  logic [31:0] imem_read_address;
  logic imem_read_enable;

  logic [31:0] dmem_load_data;
  logic dmem_read_enable;
  logic [31:0] dmem_address;
  logic dmem_write_enable;
  logic [3:0] dmem_write_byte_enable;
  logic [31:0] dmem_store_data;

  cpu #(
      .RESET_PC(RESET_PC)
  ) cpu (
      .clk                     (clk),
      .rst                     (rst),
      .imem_load_data_i        (imem_load_data),
      .dmem_load_data_i        (dmem_load_data),
      .dmem_store_data_o       (dmem_store_data),
      .dmem_write_enable_o     (dmem_write_enable),
      .dmem_write_byte_enable_o(dmem_write_byte_enable),
      .dmem_read_enable_o      (dmem_read_enable),
      .imem_read_enable_o      (imem_read_enable),
      .imem_read_address_o     (imem_read_address),
      .dmem_address_o          (dmem_address)
  );

  memory #(
      .MEM_WORDS(MEM_WORDS),
      .INIT_FILE(MEMORY_INIT_FILE)
  ) memory (
      .clk                       (clk),
      .port_a_read_address_i     (imem_read_address),
      .port_a_read_enable_i      (imem_read_enable),
      .port_a_read_data_o        (imem_load_data),
      .port_b_read_address_i     (dmem_address),
      .port_b_write_address_i    (dmem_address),
      .port_b_write_enable_i     (dmem_write_enable),
      .port_b_write_byte_enable_i(dmem_write_byte_enable),
      .port_b_read_enable_i      (dmem_read_enable),
      .port_b_write_data_i       (dmem_store_data),
      .port_b_read_data_o        (dmem_load_data)
  );

endmodule
