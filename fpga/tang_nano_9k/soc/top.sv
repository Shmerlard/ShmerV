module soc_top #(
    parameter int unsigned INPUT_CLOCK_HZ = 27_000_000,
    parameter int unsigned CLOCK_DIVIDE = 4,
    parameter bit ENABLE_HDMI = 1'b1
) (
    input wire clk,
    input wire reset_button_n_i,
    inout wire [7:0] port_a_io,
    inout wire [7:0] port_b_io,
    inout wire [7:0] port_c_io,
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n
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
  logic [DividerWidth-1:0] clock_divider = '0;
  always @(posedge clk) clock_divider <= clock_divider + 1'b1;
  // Keep the named CPU clock separate from the counter's data feedback.
  (* syn_keep = 1 *) logic cpu_clk = 1'b0;
  always @(posedge clk) cpu_clk <= clock_divider[DividerWidth-1];

  wire pixel_clk, serializer_clk, pll_locked;
  wire external_reset = !reset_button_n_i;
  wire pixel_reset_request = external_reset || !pll_locked;
  wire pixel_reset;
  wire [9:0] hdmi_symbols [0:2];
  if (ENABLE_HDMI) begin : generate_hdmi
  logic [3:0] pixel_reset_pipeline = '1;
  assign pixel_reset = pixel_reset_pipeline[3];
  hdmi_clocks clocks (
      .clk(clk), .reset(external_reset), .serializer_clk(serializer_clk),
      .pixel_clk(pixel_clk), .locked(pll_locked)
  );
  // Assert on reset/lock loss, release synchronously in the pixel domain.
  always_ff @(posedge pixel_clk or posedge pixel_reset_request) begin
    if (pixel_reset_request) pixel_reset_pipeline <= '1;
    else pixel_reset_pipeline <= {pixel_reset_pipeline[2:0], 1'b0};
  end
  hdmi_output display_output (
      .pixel_clk(pixel_clk), .serializer_clk(serializer_clk),
      .reset(pixel_reset), .symbols(hdmi_symbols),
      .tmds_clk_p(tmds_clk_p), .tmds_clk_n(tmds_clk_n),
      .tmds_d_p(tmds_d_p), .tmds_d_n(tmds_d_n)
  );
  end else begin : generate_no_hdmi
    assign pixel_clk = 1'b0;
    assign serializer_clk = 1'b0;
    assign pll_locked = 1'b0;
    assign pixel_reset = 1'b1;
    assign tmds_clk_p = 1'b0;
    assign tmds_clk_n = 1'b0;
    assign tmds_d_p = '0;
    assign tmds_d_n = '0;
  end

  logic [7:0] gpio0_pin_input;
  logic [7:0] gpio0_pin_output;
  logic [7:0] gpio0_pin_output_enable;
  logic [7:0] gpio1_pin_input;
  logic [7:0] gpio1_pin_output;
  logic [7:0] gpio1_pin_output_enable;
  logic [7:0] gpio2_pin_input;
  logic [7:0] gpio2_pin_output;
  logic [7:0] gpio2_pin_output_enable;

  soc #(
      .ENABLE_HDMI     (ENABLE_HDMI),
      .MEM_WORDS       (4096),
      .HDMI_CHAR_INIT_FILE("rtl/peripherals/hdmi/examples/char_empty.hex"),
      .CLOCK_HZ        (ClockHz),
      .MEMORY_INIT_FILE("build/fpga/tang_nano_9k/soc/software/program.hex"),
      .MEMORY_INIT_FILE_LANE0("build/fpga/tang_nano_9k/soc/software/program_lane0.hex"),
      .MEMORY_INIT_FILE_LANE1("build/fpga/tang_nano_9k/soc/software/program_lane1.hex"),
      .MEMORY_INIT_FILE_LANE2("build/fpga/tang_nano_9k/soc/software/program_lane2.hex"),
      .MEMORY_INIT_FILE_LANE3("build/fpga/tang_nano_9k/soc/software/program_lane3.hex"),
      .RESET_PC        (32'h8000_0000),
      .RAM_BASE_ADDRESS(32'h8000_0000)
  ) soc (
      .clk              (cpu_clk),
      .rst              (~reset_button_n_i),
      .hdmi_pixel_clk_i(pixel_clk),
      .hdmi_pixel_rst_i(pixel_reset),
      .hdmi_enable_i(1'b1),
      .hdmi_symbols_o(hdmi_symbols),
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
