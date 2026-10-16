import hdmi_types::*;

module hdmi_text_renderer #(
    parameter string FONT_FILE = "rtl/peripherals/hdmi/fonts/NICER40C.hex",
    parameter logic [2:0] WINDOW_OFFSET = 3'd5,
    parameter int unsigned CPU_CLOCK_HZ = 843_750
) (
    input logic cpu_clk,
    input logic pixel_clk,
    input logic rst,
    input logic pixel_rst,
    input logic enable_i,
    input logic cursor_enable,
    input logic cursor_blink,
    input char_pos_t cursor_pos,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic active_video,
    output char_pos_t char_address_o,
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

  // Capture the cursor selection on the same edge as the RAM response.
  // Retain the existing CPU-clock blink timing and pixel-clock sampling.
  always_ff @(posedge pixel_clk) begin
    if (char_read_o) display_cursor_active <= char_address_o == cursor_pos && cursor_blink_visible;
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
      .BLINK_PERIOD_MS(500)
  ) blink (
      .cpu_clk(cpu_clk),
      .rst(rst),
      .cursor_enable(cursor_enable),
      .cursor_blink(cursor_blink),
      .cursor_visible(cursor_blink_visible)
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
      .char_address_generator_o(char_address_o),
      .char_read_data_generator_i(display_cell),
      .char_read_enable_generator_o(char_read_o),
      .font_read_enable_o(font_read),
      .font_char_code_o(font_char_code),
      .font_row_o(font_row),
      .font_bitmap_i(font_bitmap),
      .palette_index_o(palette_index),
      .palette_rgb_i(palette_rgb),
      .pixel_rgb(rgb_o)
  );
endmodule
