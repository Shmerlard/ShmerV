module cpu_system_top (
    input wire clk,
    input wire reset_button_n_i,
    inout wire [7:0] port_a_io,
    inout wire [7:0] port_b_io
);
  logic [7:0] gpio0_pin_input;
  logic [7:0] gpio0_pin_output;
  logic [7:0] gpio0_pin_output_enable;
  logic [7:0] gpio1_pin_input;
  logic [7:0] gpio1_pin_output;
  logic [7:0] gpio1_pin_output_enable;

  cpu_system #(
      .MEM_WORDS       (4096),
      .MEMORY_INIT_FILE("build/fpga/tang_nano_9k/cpu_system/software/program.hex"),
      .RESET_PC        (32'h8000_0000),
      .RAM_BASE_ADDRESS(32'h8000_0000)
  ) cpu_system (
      .clk              (clk),
      .rst              (~reset_button_n_i),
      .gpio0_pin_i      (gpio0_pin_input),
      .gpio0_pin_o      (gpio0_pin_output),
      .gpio0_pin_oe_o   (gpio0_pin_output_enable),
      .gpio1_pin_i      (gpio1_pin_input),
      .gpio1_pin_o      (gpio1_pin_output),
      .gpio1_pin_oe_o   (gpio1_pin_output_enable),
      .peripheral_irq_o (),
      .address_overlap_o()
  );

  for (genvar pin = 0; pin < 8; pin++) begin : generate_bidirectional_pins
    IOBUF port_a_buffer (
        .O  (gpio0_pin_input[pin]),
        .IO (port_a_io[pin]),
        .I  (gpio0_pin_output[pin]),
        .OEN(~gpio0_pin_output_enable[pin])
    );

    IOBUF port_b_buffer (
        .O  (gpio1_pin_input[pin]),
        .IO (port_b_io[pin]),
        .I  (gpio1_pin_output[pin]),
        .OEN(~gpio1_pin_output_enable[pin])
    );
  end
endmodule
