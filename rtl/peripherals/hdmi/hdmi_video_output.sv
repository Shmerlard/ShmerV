import hdmi_types::*;

module hdmi_video_output #(
    parameter logic [2:0] WINDOW_OFFSET = 3'd5
) (
    input logic pixel_clk,
    input logic pixel_rst,
    input pixel_rgb_t rgb_i,
    output logic [9:0] x,
    output logic [9:0] y,
    output logic active_video,
    output logic [9:0] tmds_symbols_o[0:2]
);
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t   ver_state;

  hdmi_timer #(
      .WINDOW_OFFSET(WINDOW_OFFSET)
  ) timing (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .hor_state(hor_state),
      .ver_state(ver_state),
      .x(x),
      .y(y),
      .active_video(active_video)
  );
  hdmi_tmds_encoder blue_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb_i.b_pixel),
      .active_video(active_video),
      .control({ver_state != HDMI_VER_VSYNC, hor_state != HDMI_HOR_HSYNC}),
      .symbol(tmds_symbols_o[0])
  );
  hdmi_tmds_encoder green_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb_i.g_pixel),
      .active_video(active_video),
      .control(2'b00),
      .symbol(tmds_symbols_o[1])
  );
  hdmi_tmds_encoder red_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb_i.r_pixel),
      .active_video(active_video),
      .control(2'b00),
      .symbol(tmds_symbols_o[2])
  );
endmodule
