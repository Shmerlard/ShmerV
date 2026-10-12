module hdmi_test_top #(
    // Paths are relative to the standalone Gowin project directory.
    parameter PIXEL_INIT_FILE = "images/shmerv_pixels.hex",
    parameter HUE_PALETTE_PREFIX = "images/shmerv"
) (
    input wire clk,
    input wire reset_button_n_i,
    input wire animation_button_n_i,
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n
);
  import hdmi_types::*;
  wire pixel_clk, serializer_clk, pll_locked;
  wire external_reset = !reset_button_n_i;
  wire reset_request = external_reset || !pll_locked;
  logic [3:0] reset_pipeline = '1;
  wire pixel_reset = reset_pipeline[3];
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t ver_state;
  logic [9:0] x, y;
  logic active_video;
  logic [7:0] red, green, blue;
  wire hsync = hor_state != HDMI_HOR_HSYNC;
  wire vsync = ver_state != HDMI_VER_VSYNC;
  wire image_active, image_hsync, image_vsync;
  wire [9:0] symbols [0:2];
  wire [2:0] serial_data;
  wire serial_clock;
  (* ASYNC_REG = "TRUE" *) logic [1:0] button_sync;
  wire hold_original = !button_sync[1];
  wire frame_tick = (x == 10'd799) && (y == 10'd479);
  wire [7:0] hue;

  // S2 is hardware-debounced; only clock-domain synchronization is needed.
  always_ff @(posedge pixel_clk) begin
    if (pixel_reset) button_sync <= 2'b11;
    else button_sync <= {button_sync[0], animation_button_n_i};
  end
  hdmi_hue_animation animation (
      .clk(pixel_clk), .rst(pixel_reset), .frame_tick(frame_tick),
      .hold_original(hold_original), .hue(hue)
  );

  hdmi_test_clocks clocks (
      .clk(clk), .reset(external_reset), .pixel_clk(pixel_clk),
      .serializer_clk(serializer_clk), .locked(pll_locked)
  );

  // Assert immediately on button/lock loss; release on pixel-clock edges.
  always_ff @(posedge pixel_clk or posedge reset_request) begin
    if (reset_request) reset_pipeline <= '1;
    else reset_pipeline <= {reset_pipeline[2:0], 1'b0};
  end

  hdmi_timer timing (
      .clk(pixel_clk), .rst(pixel_reset), .hor_state(hor_state),
      .ver_state(ver_state), .x(x), .y(y), .active_video(active_video)
  );
  hdmi_image_generator #(
      .PIXEL_INIT_FILE(PIXEL_INIT_FILE), .HUE_PALETTE_PREFIX(HUE_PALETTE_PREFIX)
  ) pixels (
      .clk(pixel_clk), .rst(pixel_reset), .x(x), .y(y),
      .active_video(active_video), .hsync(hsync), .vsync(vsync),
      .hue(hue),
      .red(red), .green(green), .blue(blue),
      .active_video_o(image_active), .hsync_o(image_hsync), .vsync_o(image_vsync)
  );
  hdmi_tmds_encoder blue_encoder (
      .clk(pixel_clk), .rst(pixel_reset), .color(blue),
      .active_video(image_active), .control({image_vsync, image_hsync}), .symbol(symbols[0])
  );
  hdmi_tmds_encoder green_encoder (
      .clk(pixel_clk), .rst(pixel_reset), .color(green),
      .active_video(image_active), .control(2'b00), .symbol(symbols[1])
  );
  hdmi_tmds_encoder red_encoder (
      .clk(pixel_clk), .rst(pixel_reset), .color(red),
      .active_video(image_active), .control(2'b00), .symbol(symbols[2])
  );

  // Five low bits followed by five high bits make the forwarded pixel clock.
  hdmi_test_serializer clock_serializer (
      .pixel_clk(pixel_clk), .serializer_clk(serializer_clk),
      .reset(pixel_reset), .symbol(10'b1111100000), .serial(serial_clock)
  );
  ELVDS_OBUF clock_output_buffer (
      .I(serial_clock),
      .O(tmds_clk_p),
      .OB(tmds_clk_n)
  );

  for (genvar channel = 0; channel < 3; channel++) begin : generate_data_buffers
    hdmi_test_serializer data_serializer (
        .pixel_clk(pixel_clk), .serializer_clk(serializer_clk),
        .reset(pixel_reset), .symbol(symbols[channel]), .serial(serial_data[channel])
    );
    ELVDS_OBUF data_output_buffer (
        .I(serial_data[channel]),
        .O(tmds_d_p[channel]),
        .OB(tmds_d_n[channel])
    );
  end
endmodule
