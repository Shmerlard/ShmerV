import hdmi_types::*;

module hdmi_module #(
    parameter string FONT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter string CHAR_INIT_FILE = "",
    parameter logic [2:0] WINDOW_OFFSET = 3'd5
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,
    // Pixel-domain reset and enable, independent of the CPU interface.
    input logic pixel_rst,
    input logic enable_i,

    input char_pos_t pixel_address_cpu_i,
    input char_cell_t pixel_write_data_cpu_i,
    output char_cell_t pixel_read_data_cpu_o,
    input logic pixel_write_enable_cpu_i,
    input logic pixel_read_enable_cpu_i,

    // Parallel TMDS symbols for the FPGA serializer: 0=blue, 1=green, 2=red.
    output logic [9:0] tmds_symbols_o[0:2]
);
  char_pos_t generator_address;
  char_cell_t generator_data;
  logic generator_read;
  logic [9:0] x, y;
  logic active_video;
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t ver_state;
  pixel_rgb_t rgb;
  logic font_read;
  logic [7:0] font_char_code, font_bitmap;
  logic [3:0] font_row, palette_index;
  logic [23:0] palette_rgb;

  hdmi_char_memory #(
      .INIT_FILE(CHAR_INIT_FILE)
  ) char_memory (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .rst(rst),
      .pixel_address_cpu_i(pixel_address_cpu_i),
      .pixel_write_data_cpu_i(pixel_write_data_cpu_i),
      .pixel_read_data_cpu_o(pixel_read_data_cpu_o),
      .pixel_write_enable_cpu_i(pixel_write_enable_cpu_i),
      .pixel_read_enable_cpu_i(pixel_read_enable_cpu_i),
      .pixel_address_generator_i(generator_address),
      .pixel_read_data_generator_o(generator_data),
      .pixel_read_enable_generator_i(generator_read)
  );

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
  hdmi_font_rom #(
      .FONT_FILE(FONT_FILE)
  ) font_rom (
      .clk(pixel_clk),
      .read_enable_i(font_read),
      .char_code_i(font_char_code),
      .row_i(font_row),
      .row_bitmap_o(font_bitmap),
      .color_index_i(palette_index),
      .color_rgb_o(palette_rgb)
  );
  hdmi_pixel_generator #(
      .WINDOW_OFFSET(WINDOW_OFFSET)
  ) pixels (
      .hdmi_clk(pixel_clk),
      .rst(pixel_rst),
      .enable_i(enable_i),
      .x_pixel_pos(x),
      .y_pixel_pos(y),
      .active_pixel(active_video),
      .char_address_generator_o(generator_address),
      .char_read_data_generator_i(generator_data),
      .char_read_enable_generator_o(generator_read),
      .font_read_enable_o(font_read),
      .font_char_code_o(font_char_code),
      .font_row_o(font_row),
      .font_bitmap_i(font_bitmap),
      .palette_index_o(palette_index),
      .palette_rgb_i(palette_rgb),
      .pixel_rgb(rgb)
  );
  hdmi_tmds_encoder blue_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb.b_pixel),
      .active_video(active_video),
      .control({ver_state != HDMI_VER_VSYNC, hor_state != HDMI_HOR_HSYNC}),
      .symbol(tmds_symbols_o[0])
  );
  hdmi_tmds_encoder green_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb.g_pixel),
      .active_video(active_video),
      .control(2'b00),
      .symbol(tmds_symbols_o[1])
  );
  hdmi_tmds_encoder red_encoder (
      .clk(pixel_clk),
      .rst(pixel_rst),
      .color(rgb.r_pixel),
      .active_video(active_video),
      .control(2'b00),
      .symbol(tmds_symbols_o[2])
  );
endmodule
