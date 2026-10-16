import hdmi_types::*;

module hdmi_text_renderer #(
    parameter string FONT_INIT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter logic [2:0] VIDEO_X_OFFSET_PIXELS = 3'd5,
    parameter int unsigned CPU_CLOCK_HZ = 843_750,
    parameter int TEXT_COLUMNS = 80,
    parameter int TEXT_BUFFER_ROWS = 51,
    parameter int unsigned BLINK_INTERVAL_MS = 500
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,
    input logic pixel_rst,

    input logic enable_i,
    input logic active_video_i,

    input logic cursor_enable_i,
    input logic cursor_blink_i,
    input logic [11:0] cursor_index_i,
    input logic [5:0] start_row_i,

    input logic [9:0] scan_pixel_x_i,
    input logic [9:0] scan_pixel_y_i,

    output logic [11:0] char_index_o,
    input char_cell_t char_data_i,
    output logic char_read_o,
    output pixel_rgb_t rgb_o
);
  logic cursor_blink_visible, display_cursor_active;
  char_cell_t display_cell;
  logic font_read;
  logic [7:0] font_char_code, font_bitmap;
  logic [3:0] font_row, palette_index;
  logic [23:0] palette_rgb;

  screen_cell_pos_t screen_cell_pos;

  // Capture the cursor selection on the same edge as the RAM response.
  // Retain the existing CPU-clock blink timing and pixel-clock sampling.
  always_ff @(posedge pixel_clk) begin
    if (char_read_o)
      display_cursor_active <= char_index_o == cursor_index_i && cursor_blink_visible;
  end

  always_comb begin
    // TODO: Use TEXT_BUFFER_ROWS to validate that the visible window fits in RAM.
    char_index_o = $unsigned(12'((int'(start_row_i) + int'(screen_cell_pos.y_pos))
        * TEXT_COLUMNS + int'(screen_cell_pos.x_pos)));
  end
  always_comb begin
    display_cell = char_data_i;
    if (display_cursor_active) begin
      display_cell.char_code = 8'h5F;
      display_cell.fg_col = HDMI_COLOR_WHITE;
      display_cell.bg_col = HDMI_COLOR_BLACK;
    end
  end

  hdmi_blink_module #(
      .CPU_CLOCK_HZ(CPU_CLOCK_HZ),
      .BLINK_INTERVAL_MS(BLINK_INTERVAL_MS)
  ) blink (
      .cpu_clk(cpu_clk),
      .rst(rst),
      .cursor_enable_i(cursor_enable_i),
      .cursor_blink_i(cursor_blink_i),
      .cursor_visible_o(cursor_blink_visible)
  );

  hdmi_font_rom #(
      .FONT_INIT_FILE(FONT_INIT_FILE)
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
      .VIDEO_X_OFFSET_PIXELS(VIDEO_X_OFFSET_PIXELS)
  ) pixels (
      .pixel_clk(pixel_clk),
      .rst(pixel_rst),
      .enable_i(enable_i),
      .scan_pixel_x_i(scan_pixel_x_i),
      .scan_pixel_y_i(scan_pixel_y_i),
      .active_video_i(active_video_i),

      .screen_cell_pos_o(screen_cell_pos),
      .cell_data_i(display_cell),
      .cell_read_enable_o(char_read_o),

      .font_read_enable_o(font_read),
      .font_char_code_o(font_char_code),
      .font_row_o(font_row),
      .font_bitmap_i(font_bitmap),

      .palette_index_o(palette_index),
      .palette_rgb_i(palette_rgb),
      .pixel_rgb_o(rgb_o)
  );
endmodule
