import hdmi_types::*;

module hdmi_pixel_generator #(
    parameter logic [2:0] WINDOW_OFFSET = 3'd5
) (
    input logic hdmi_clk,
    input logic rst,
    input logic enable_i,

    // Raw timer coordinates; active_pixel comes from the shifted timer.
    input logic [9:0] x_pixel_pos,
    input logic [9:0] y_pixel_pos,
    input logic       active_pixel,

    //From char memory
    output char_pos_t char_address_generator_o,
    input char_cell_t char_read_data_generator_i,
    output logic char_read_enable_generator_o,

    output logic font_read_enable_o,
    output logic [7:0] font_char_code_o,
    output logic [3:0] font_row_o,
    input logic [7:0] font_bitmap_i,
    output logic [3:0] palette_index_o,
    input logic [23:0] palette_rgb_i,

    output pixel_rgb_t pixel_rgb

);

  typedef struct packed {
    logic [7:0] bitmap;
    pixel_rgb_t foreground;
    pixel_rgb_t background;
  } cached_row_t;

  cached_row_t current_row, next_row;
  logic current_valid, next_valid;
  logic char_pending, font_pending;
  logic [3:0] requested_font_row, background_index;
  logic [9:0] display_x;
  logic load_current;

  // Request one cell every eight clocks, ahead of its displayed pixels.
  assign char_address_generator_o.x_pos = x_pixel_pos[9:3];
  assign char_address_generator_o.y_pos = y_pixel_pos[8:4];
  assign char_read_enable_generator_o = enable_i && !rst
      && y_pixel_pos < 10'd480 && x_pixel_pos < 10'd640
      && x_pixel_pos[2:0] == 3'd0;

  // Following the character response, read the glyph and cache foreground.
  // On the next clock, cache the glyph response and background color.
  assign palette_index_o = char_pending ? char_read_data_generator_i.fg_col : background_index;
  assign font_read_enable_o = char_pending && enable_i && !rst;
  assign font_char_code_o = char_read_data_generator_i.char_code;
  assign font_row_o = requested_font_row;

  assign display_x = x_pixel_pos - 10'(WINDOW_OFFSET);
  // Load on the edge immediately before the timer reaches a cell boundary.
  assign load_current = y_pixel_pos < 10'd480
      && x_pixel_pos >= 10'(WINDOW_OFFSET) - 10'd1
      && x_pixel_pos < 10'd640 + 10'(WINDOW_OFFSET) - 10'd1
      && x_pixel_pos[2:0] == WINDOW_OFFSET - 3'd1;

  always_ff @(posedge hdmi_clk) begin
    if (rst || !enable_i) begin
      current_row <= '0;
      next_row <= '0;
      current_valid <= 1'b0;
      next_valid <= 1'b0;
      char_pending <= 1'b0;
      font_pending <= 1'b0;
      requested_font_row <= '0;
      background_index <= '0;
    end else begin
      char_pending <= char_read_enable_generator_o;
      font_pending <= char_pending;
      if (char_read_enable_generator_o) requested_font_row <= y_pixel_pos[3:0];
      if (char_pending) begin
        next_row.foreground <= pixel_rgb_t'(palette_rgb_i);
        background_index <= char_read_data_generator_i.bg_col;
      end
      if (font_pending) begin
        next_row.bitmap <= font_bitmap_i;
        next_row.background <= pixel_rgb_t'(palette_rgb_i);
        next_valid <= 1'b1;
      end
      if (load_current) begin
        current_row <= next_row;
        current_valid <= next_valid;
        next_valid <= 1'b0;
      end
      if (x_pixel_pos == 10'd799) current_valid <= 1'b0;
    end
  end

  always_comb begin
    pixel_rgb = '0;
    if (!rst && enable_i && active_pixel && current_valid) begin
      // Raw VGA font rows store their leftmost pixel in bit 7.
      pixel_rgb = current_row.bitmap[3'd7 - display_x[2:0]]
          ? current_row.foreground : current_row.background;
    end
  end

`ifndef SYNTHESIS
  initial begin
    assert (WINDOW_OFFSET >= 3'd4)
    else $fatal(1, "Text generator requires WINDOW_OFFSET between 4 and 7");
  end
`endif
endmodule
