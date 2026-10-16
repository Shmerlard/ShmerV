import hdmi_types::*;

module hdmi_pixel_generator #(
    parameter logic [2:0] VIDEO_X_OFFSET_PIXELS = 3'd5
) (
    input logic pixel_clk,
    input logic rst,
    input logic enable_i,

    // Raw timer coordinates; active_video_i comes from the shifted timer.
    input logic [9:0] scan_pixel_x_i,
    input logic [9:0] scan_pixel_y_i,
    input logic       active_video_i,

    //From char memory
    output screen_cell_pos_t screen_cell_pos_o,
    input char_cell_t cell_data_i,
    output logic cell_read_enable_o,

    output logic font_read_enable_o,
    output logic [7:0] font_char_code_o,
    output logic [3:0] font_row_o,
    input logic [7:0] font_bitmap_i,
    output logic [3:0] palette_index_o,
    input logic [23:0] palette_rgb_i,

    output pixel_rgb_t pixel_rgb_o

);

  typedef struct packed {
    logic [7:0] bitmap;
    pixel_rgb_t foreground;
    pixel_rgb_t background;
  } glyph_row_cache_t;

  glyph_row_cache_t current_glyph_row, next_glyph_row;
  logic current_glyph_valid, next_glyph_valid;
  logic cell_response_valid, font_response_valid;
  logic [3:0] requested_glyph_row, background_color_index;
  logic [9:0] display_pixel_x;
  logic load_next_glyph;

  // Request one cell every eight clocks, ahead of its displayed pixels.
  assign screen_cell_pos_o.x_pos = scan_pixel_x_i[9:3];
  assign screen_cell_pos_o.y_pos = scan_pixel_y_i[8:4];
  assign cell_read_enable_o = enable_i && !rst
      && scan_pixel_y_i < 10'd480 && scan_pixel_x_i < 10'd640
      && scan_pixel_x_i[2:0] == 3'd0;

  // Following the character response, read the glyph and cache foreground.
  // On the next clock, cache the glyph response and background color.
  assign palette_index_o = cell_response_valid ? cell_data_i.fg_col : background_color_index;
  assign font_read_enable_o = cell_response_valid && enable_i && !rst;
  assign font_char_code_o = cell_data_i.char_code;
  assign font_row_o = requested_glyph_row;

  assign display_pixel_x = scan_pixel_x_i - 10'(VIDEO_X_OFFSET_PIXELS);
  // Load on the edge immediately before the timer reaches a cell boundary.
  assign load_next_glyph = scan_pixel_y_i < 10'd480
      && scan_pixel_x_i >= 10'(VIDEO_X_OFFSET_PIXELS) - 10'd1
      && scan_pixel_x_i < 10'd640 + 10'(VIDEO_X_OFFSET_PIXELS) - 10'd1
      && scan_pixel_x_i[2:0] == VIDEO_X_OFFSET_PIXELS - 3'd1;

  always_ff @(posedge pixel_clk) begin
    if (rst || !enable_i) begin
      current_glyph_row <= '0;
      next_glyph_row <= '0;
      current_glyph_valid <= 1'b0;
      next_glyph_valid <= 1'b0;
      cell_response_valid <= 1'b0;
      font_response_valid <= 1'b0;
      requested_glyph_row <= '0;
      background_color_index <= '0;
    end else begin
      cell_response_valid <= cell_read_enable_o;
      font_response_valid <= cell_response_valid;
      if (cell_read_enable_o) requested_glyph_row <= scan_pixel_y_i[3:0];
      if (cell_response_valid) begin
        next_glyph_row.foreground <= pixel_rgb_t'(palette_rgb_i);
        background_color_index <= cell_data_i.bg_col;
      end
      if (font_response_valid) begin
        next_glyph_row.bitmap <= font_bitmap_i;
        next_glyph_row.background <= pixel_rgb_t'(palette_rgb_i);
        next_glyph_valid <= 1'b1;
      end
      if (load_next_glyph) begin
        current_glyph_row <= next_glyph_row;
        current_glyph_valid <= next_glyph_valid;
        next_glyph_valid <= 1'b0;
      end
      if (scan_pixel_x_i == 10'd799) current_glyph_valid <= 1'b0;
    end
  end

  always_comb begin
    pixel_rgb_o = '0;
    if (!rst && enable_i && active_video_i && current_glyph_valid) begin
      // Raw VGA font rows store their leftmost pixel in bit 7.
      pixel_rgb_o = current_glyph_row.bitmap[3'd7 - display_pixel_x[2:0]]
          ? current_glyph_row.foreground : current_glyph_row.background;
    end
  end

`ifndef SYNTHESIS
  initial begin
    assert (VIDEO_X_OFFSET_PIXELS >= 3'd4)
    else $fatal(1, "Text generator requires VIDEO_X_OFFSET_PIXELS between 4 and 7");
  end
`endif
endmodule
