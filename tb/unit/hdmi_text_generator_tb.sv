module hdmi_text_generator_tb;
  import hdmi_types::*;
  parameter logic [2:0] OFFSET = 3'd5;
  parameter int START_ROW = 0;
  parameter bit CURSOR_ENABLE = 1'b1;
  parameter int CURSOR_INDEX = 80;
  bit pixel_clk = 0, cpu_clk = 0;
  logic rst = 1, enable = 1;
  logic [9:0] x, y;
  logic active_video;
  logic [11:0] cpu_address, display_address;
  char_cell_t cpu_data, display_data;
  logic cpu_write = 0, display_read;
  pixel_rgb_t rgb;
  logic [7:0] reference_font[0:4095];
  int requests = 0;

  always #5 pixel_clk = ~pixel_clk;
  always #7 cpu_clk = ~cpu_clk;
  hdmi_char_memory memory (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .char_index_controller_i(cpu_address),
      .char_write_data_controller_i(cpu_data),
      .char_read_data_controller_o(),
      .char_write_enable_controller_i(cpu_write),
      .char_read_enable_controller_i(1'b0),
      .char_index_renderer_i(display_address),
      .char_read_data_renderer_o(display_data),
      .char_read_enable_renderer_i(display_read)
  );
  hdmi_text_renderer #(
      .VIDEO_X_OFFSET_PIXELS(OFFSET)
  ) renderer (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .rst(rst),
      .pixel_rst(rst),
      .enable_i(enable),
      .active_video_i(active_video),
      .cursor_enable_i(CURSOR_ENABLE),
      .cursor_blink_i(1'b0),
      .cursor_index_i(12'(CURSOR_INDEX)),
      .start_row_i(6'(START_ROW)),
      .scan_pixel_x_i(x),
      .scan_pixel_y_i(y),
      .char_index_o(display_address),
      .char_data_i(display_data),
      .char_read_o(display_read),
      .rgb_o(rgb)
  );
  hdmi_video_output #(
      .VIDEO_X_OFFSET_PIXELS(OFFSET)
  ) video_output (
      .pixel_clk(pixel_clk),
      .pixel_rst(rst),
      .rgb_i(rgb),
      .scan_pixel_x_o(x),
      .scan_pixel_y_o(y),
      .active_video_o(active_video),
      .tmds_symbols_o()
  );

  function automatic char_cell_t cell_value(input int column, input int row);
    char_cell_t cell_data;
    cell_data.char_code = 8'(column + row * 80);
    cell_data.fg_col = column % 2 == 0 ? 4'h1 : 4'h2;
    cell_data.bg_col = row % 2 == 0 ? 4'h4 : 4'hF;
    return cell_data;
  endfunction

  task automatic check_pixel;
    int screen_x, glyph_address;
    char_cell_t cell_data;
    logic [23:0] expected_rgb;
    bit cursor_cell;
    expected_rgb = 0;
    if (active_video) begin
      screen_x = int'(x) - int'(OFFSET);
      cell_data = cell_value(screen_x / 8, START_ROW + int'(y) / 16);
      cursor_cell = CURSOR_ENABLE && (START_ROW + int'(y) / 16) * 80 + screen_x / 8 == CURSOR_INDEX;
      if (cursor_cell) cell_data.char_code = 8'h5F;
      glyph_address = int'(cell_data.char_code) * 16 + int'(y) % 16;
      if (reference_font[glyph_address][7-screen_x%8])
        expected_rgb = cursor_cell ? 24'hFFFFFF
            : (cell_data.fg_col == 4'h1 ? 24'h0000AA : 24'h00AA00);
      else
        expected_rgb = cursor_cell ? 24'h000000
          : (cell_data.bg_col == 4'h4 ? 24'hAA0000 : 24'hFFFFFF);
    end
    assert (rgb == expected_rgb)
    else $fatal(1, "Pixel (%0d,%0d): got %h expected %h", x, y, rgb, expected_rgb);
    assert (display_read == (x < 640 && y < 480 && x[2:0] == 0))
    else $fatal(1, "Unexpected character read");
    if (display_read) begin
      assert (int'(display_address) == (START_ROW + int'(y) / 16) * 80 + int'(x) / 8)
      else $fatal(1, "Wrong cell address");
      requests++;
    end
  endtask

  initial begin
    $readmemh("rtl/peripherals/hdmi/fonts/NICER40C.hex", reference_font);
    // Initialize using the independent CPU clock, keeping the display reset.
    @(negedge cpu_clk);
    for (int row = 0; row < 51; row++) begin
      for (int column = 0; column < 80; column++) begin
        cpu_address = 12'(row * 80 + column);
        cpu_data = cell_value(column, row);
        cpu_write = 1;
        @(negedge cpu_clk);
      end
    end
    cpu_write = 0;
    @(negedge pixel_clk);
    rst = 0;
    #1;
    for (int position = 0; position < 800 * 525; position++) begin
      check_pixel();
      @(negedge pixel_clk);
    end
    assert (requests == 80 * 480)
    else $fatal(1, "Wrong reads per frame");
    // Disable must suppress both reads and pixels; reset must restart prefetch.
    enable = 0;
    #1;
    assert (rgb == 0 && !display_read)
    else $fatal(1, "Disable failed");
    rst = 1;
    @(negedge pixel_clk);
    enable = 1;
    rst = 0;
    #1;
    repeat (20) begin
      check_pixel();
      @(negedge pixel_clk);
    end
    $display("PASS: full text frame, two row caches, dual-clock RAM, offset %0d, disable/reset",
             OFFSET);
    $finish;
  end
endmodule
