import hdmi_types::*;

module hdmi_video_output #(
    parameter logic [2:0] VIDEO_X_OFFSET_PIXELS = 3'd5
) (
    input logic pixel_clk,
    input logic pixel_rst,
    input pixel_rgb_t rgb_i,
    output logic [9:0] scan_pixel_x_o,
    output logic [9:0] scan_pixel_y_o,
    output logic active_video_o,

    output logic [9:0] tmds_symbols_o[0:2]
);
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t   ver_state;

  hdmi_timer #(
      .VIDEO_X_OFFSET_PIXELS(VIDEO_X_OFFSET_PIXELS)
  ) timing (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .hor_state_o(hor_state),
      .ver_state_o(ver_state),
      .scan_pixel_x_o(scan_pixel_x_o),
      .scan_pixel_y_o(scan_pixel_y_o),
      .active_video_o(active_video_o)
  );
  hdmi_tmds_encoder blue_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color_i(rgb_i.b_pixel),
      .active_video_i(active_video_o),
      .control_i({ver_state != HDMI_VER_VSYNC, hor_state != HDMI_HOR_HSYNC}),
      .symbol_o(tmds_symbols_o[0])
  );
  hdmi_tmds_encoder green_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color_i(rgb_i.g_pixel),
      .active_video_i(active_video_o),
      .control_i(2'b00),
      .symbol_o(tmds_symbols_o[1])
  );
  hdmi_tmds_encoder red_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color_i(rgb_i.r_pixel),
      .active_video_i(active_video_o),
      .control_i(2'b00),
      .symbol_o(tmds_symbols_o[2])
  );
endmodule
