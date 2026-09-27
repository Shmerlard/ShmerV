module gpio_fpga_top (
    input  logic [7:0] dip_n_i,
    input  logic       clock_button_n_i,
    input  logic       reset_button_n_i,
    input  logic       write_button_n_i,
    output logic [7:0] led_o
);
  logic [7:0] pin_output;

  gpio #(
      .WIDTH(8),
      .ALT_MASK('0),
      .IRQ_MASK('0)
  ) gpio (
      .clk                (~clock_button_n_i),
      .rst                (~reset_button_n_i),
      .pin_i              ('0),
      .pin_o              (pin_output),
      .pin_oe_o           (),
      .alt_in_o           (),
      .alt_out_i          ('0),
      .alt_oe_i           ('0),
      .mmio_write_data_i  (~dip_n_i),
      .mmio_read_data_o   (),
      .register_address_i (5'h01),
      .mmio_write_enable_i(~write_button_n_i),
      .mmio_read_enable_i (1'b0),
      .irq_o              ()
  );

  assign led_o = pin_output;
endmodule
