timeunit 1ns / 1ps;
import csr_types::*;

module soc #(
    parameter int MEM_WORDS = 1024,
    parameter bit ENABLE_HDMI = 1'b1,
    parameter int unsigned CLOCK_HZ = 843_750,
    parameter int unsigned UART_BAUD_RATE = 9600,
    parameter string HDMI_CHAR_INIT_FILE = "",
    parameter string MEMORY_INIT_FILE = "",
    parameter string MEMORY_INIT_FILE_LANE0 = "",
    parameter string MEMORY_INIT_FILE_LANE1 = "",
    parameter string MEMORY_INIT_FILE_LANE2 = "",
    parameter string MEMORY_INIT_FILE_LANE3 = "",
    parameter logic [31:0] RESET_PC = 32'h0000_0000,
    parameter logic [31:0] RAM_BASE_ADDRESS = 32'h0000_0000
) (
    input logic clk,
    input logic rst,
    input logic hdmi_pixel_clk_i,
    input logic hdmi_pixel_rst_i,
    input logic hdmi_enable_i,
    output logic [9:0] hdmi_symbols_o[0:2],

    input  logic [7:0] gpio0_pin_i,
    output logic [7:0] gpio0_pin_o,
    output logic [7:0] gpio0_pin_oe_o,

    input  logic [7:0] gpio1_pin_i,
    output logic [7:0] gpio1_pin_o,
    output logic [7:0] gpio1_pin_oe_o,

    input  logic [7:0] gpio2_pin_i,
    output logic [7:0] gpio2_pin_o,
    output logic [7:0] gpio2_pin_oe_o,

    output logic address_overlap_o
);

  logic [31:0] imem_load_data;
  logic [31:0] imem_read_address;
  logic imem_read_enable;

  logic [31:0] dmem_load_data;
  logic [31:0] dmem_address;
  logic [3:0] dmem_write_byte_enable;
  logic [31:0] dmem_store_data;
  logic dmem_read_enable;
  logic dmem_write_enable;

  logic [31:0] ram_dmem_load_data;
  logic ram_dmem_read_enable;
  logic ram_dmem_write_enable;

  logic peripheral_read_enable;
  logic peripheral_write_enable;
  logic [31:0] peripheral_read_data;
  logic peripheral_irq;
  irq_address_t peripheral_irq_address;

  core #(
      .RESET_PC(RESET_PC)
  ) core (
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
      .dmem_address_o          (dmem_address),
      .ext_irq_i               (peripheral_irq),
      .ext_irq_address_i       (peripheral_irq_address)
  );

  address_decoder #(
      .RAM_BASE_ADDRESS       (RAM_BASE_ADDRESS),
      .RAM_SIZE_BYTES         (MEM_WORDS * 4),
      .PERIPHERAL_BASE_ADDRESS(soc_address_map::PERIPHERAL_BASE_ADDRESS),
      .PERIPHERAL_SIZE_BYTES  (soc_address_map::PERIPHERAL_SIZE_BYTES)
  ) address_decoder (
      .clk                      (clk),
      .rst                      (rst),
      .address_i                (dmem_address),
      .read_enable_i            (dmem_read_enable),
      .write_enable_i           (dmem_write_enable),
      .ram_read_enable_o        (ram_dmem_read_enable),
      .ram_write_enable_o       (ram_dmem_write_enable),
      .ram_read_data_i          (ram_dmem_load_data),
      .peripheral_read_enable_o (peripheral_read_enable),
      .peripheral_write_enable_o(peripheral_write_enable),
      .peripheral_read_data_i   (peripheral_read_data),
      .read_data_o              (dmem_load_data),
      .address_overlap_o        (address_overlap_o)
  );

  peripheral_manager #(
      .ENABLE_HDMI        (ENABLE_HDMI),
      .CLOCK_HZ           (CLOCK_HZ),
      .UART_BAUD_RATE     (UART_BAUD_RATE),
      .HDMI_CHAR_INIT_FILE(HDMI_CHAR_INIT_FILE)
  ) peripheral_manager (
      .clk                (clk),
      .rst                (rst),
      .hdmi_pixel_clk_i   (hdmi_pixel_clk_i),
      .hdmi_pixel_rst_i   (hdmi_pixel_rst_i),
      .hdmi_enable_i      (hdmi_enable_i),
      .hdmi_symbols_o     (hdmi_symbols_o),
      .address_i          (dmem_address),
      .write_data_i       (dmem_store_data),
      .write_byte_enable_i(dmem_write_byte_enable),
      .read_enable_i      (peripheral_read_enable),
      .write_enable_i     (peripheral_write_enable),
      .read_data_o        (peripheral_read_data),
      .gpio0_pin_i        (gpio0_pin_i),
      .gpio0_pin_o        (gpio0_pin_o),
      .gpio0_pin_oe_o     (gpio0_pin_oe_o),
      .gpio1_pin_i        (gpio1_pin_i),
      .gpio1_pin_o        (gpio1_pin_o),
      .gpio1_pin_oe_o     (gpio1_pin_oe_o),
      .gpio2_pin_i        (gpio2_pin_i),
      .gpio2_pin_o        (gpio2_pin_o),
      .gpio2_pin_oe_o     (gpio2_pin_oe_o),
      .irq_o              (peripheral_irq),
      .irq_address_o      (peripheral_irq_address)
  );

  memory #(
      .MEM_WORDS      (MEM_WORDS),
      .INIT_FILE      (MEMORY_INIT_FILE),
      .INIT_FILE_LANE0(MEMORY_INIT_FILE_LANE0),
      .INIT_FILE_LANE1(MEMORY_INIT_FILE_LANE1),
      .INIT_FILE_LANE2(MEMORY_INIT_FILE_LANE2),
      .INIT_FILE_LANE3(MEMORY_INIT_FILE_LANE3)
  ) memory (
      .clk                       (clk),
      .port_a_read_address_i     (imem_read_address),
      .port_a_read_enable_i      (imem_read_enable),
      .port_a_read_data_o        (imem_load_data),
      .port_b_address_i          (dmem_address),
      .port_b_write_enable_i     (ram_dmem_write_enable),
      .port_b_write_byte_enable_i(dmem_write_byte_enable),
      .port_b_enable_i           (ram_dmem_read_enable || ram_dmem_write_enable),
      .port_b_write_data_i       (dmem_store_data),
      .port_b_read_data_o        (ram_dmem_load_data)
  );

endmodule
