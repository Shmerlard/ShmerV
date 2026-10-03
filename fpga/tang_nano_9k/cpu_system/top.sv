module cpu_system_top #(
    parameter int unsigned INPUT_CLOCK_HZ = 27_000_000,
    parameter int unsigned CLOCK_DIVIDE = 32
) (
    input wire clk,
    input wire reset_button_n_i,
    inout wire [7:0] port_a_io,
    inout wire [7:0] port_b_io,
    inout wire [7:0] port_c_io
);
  localparam int unsigned DividerWidth = $clog2(CLOCK_DIVIDE);
  localparam int unsigned ClockHz = INPUT_CLOCK_HZ / CLOCK_DIVIDE;
  // Select a counter bit for power-of-two division with 50% duty cycle.
`ifndef SYNTHESIS
  initial begin
    assert (CLOCK_DIVIDE >= 2 && (CLOCK_DIVIDE & (CLOCK_DIVIDE - 1)) == 0)
      else $fatal(1, "CLOCK_DIVIDE must be a power of two >= 2");
    assert (INPUT_CLOCK_HZ >= CLOCK_DIVIDE)
      else $fatal(1, "Divided clock frequency must be at least 1 Hz");
  end
`endif
  // Keep this net named for clock.sdc's generated-clock constraint.
  logic [DividerWidth-1:0] clock_divider = '0;
  always @(posedge clk) clock_divider <= clock_divider + 1'b1;
  (* syn_keep = 1 *) wire cpu_clk = clock_divider[DividerWidth-1];

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
      .CLOCK_HZ        (ClockHz),
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
