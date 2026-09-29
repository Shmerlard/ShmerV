module cpu_system_top (
    input wire clk,
    input wire reset_button_n_i,
    inout wire [7:0] port_a_io,
    inout wire [7:0] port_b_io,
    inout wire [7:0] port_c_io
);
  // Divide the board's 27 MHz oscillator by 32 to 843.75 kHz.
  // Keep this net named for clock.sdc's generated-clock constraint.
  logic [4:0] clock_divider = 5'b0;
  always @(posedge clk) clock_divider <= clock_divider + 1'b1;
  (* syn_keep = 1 *) wire cpu_clk = clock_divider[4];

  logic [7:0] gpio0_pin_input;
  logic [7:0] gpio0_pin_output;
  logic [7:0] gpio0_pin_output_enable;
  logic [7:0] gpio1_pin_input;
  logic [7:0] gpio1_pin_output;
  logic [7:0] gpio1_pin_output_enable;
  logic [7:0] gpio2_pin_input;
  logic [7:0] gpio2_pin_output;
  logic [7:0] gpio2_pin_output_enable;

  cpu_system #(
      .MEM_WORDS       (4096),
      .UART_CYCLES_FOR_BIT(88),
      .MEMORY_INIT_FILE("build/fpga/tang_nano_9k/cpu_system/software/program.hex"),
      .MEMORY_INIT_FILE_LANE0("build/fpga/tang_nano_9k/cpu_system/software/program_lane0.hex"),
      .MEMORY_INIT_FILE_LANE1("build/fpga/tang_nano_9k/cpu_system/software/program_lane1.hex"),
      .MEMORY_INIT_FILE_LANE2("build/fpga/tang_nano_9k/cpu_system/software/program_lane2.hex"),
      .MEMORY_INIT_FILE_LANE3("build/fpga/tang_nano_9k/cpu_system/software/program_lane3.hex"),
      .RESET_PC        (32'h8000_0000),
      .RAM_BASE_ADDRESS(32'h8000_0000)
  ) cpu_system (
      .clk              (cpu_clk),
      .rst              (~reset_button_n_i),
      .gpio0_pin_i      (gpio0_pin_input),
      .gpio0_pin_o      (gpio0_pin_output),
      .gpio0_pin_oe_o   (gpio0_pin_output_enable),
      .gpio1_pin_i      (gpio1_pin_input),
      .gpio1_pin_o      (gpio1_pin_output),
      .gpio1_pin_oe_o   (gpio1_pin_output_enable),
      .gpio2_pin_i      (gpio2_pin_input),
      .gpio2_pin_o      (gpio2_pin_output),
      .gpio2_pin_oe_o   (gpio2_pin_output_enable),
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

    IOBUF port_c_buffer (
        .O  (gpio2_pin_input[pin]),
        .IO (port_c_io[pin]),
        .I  (gpio2_pin_output[pin]),
        .OEN(~gpio2_pin_output_enable[pin])
    );
  end
endmodule
