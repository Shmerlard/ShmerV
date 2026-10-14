module hdmi_text_generator_tb;
  import hdmi_types::*;
  parameter logic [2:0] OFFSET = 3'd5;
  bit pixel_clk = 0, cpu_clk = 0;
  logic rst = 1, enable = 1;
  logic [9:0] x, y;
  logic active_video;
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t ver_state;
  char_pos_t cpu_address, display_address;
  char_cell_t cpu_data, display_data;
  logic cpu_write = 0, display_read;
  pixel_rgb_t rgb;
  logic [7:0] reference_font[0:4095];
  int requests = 0;

  always #5 pixel_clk = ~pixel_clk;
  always #7 cpu_clk = ~cpu_clk;
  hdmi_module #(
      .WINDOW_OFFSET(OFFSET)
  ) dut (
      .cpu_clk(cpu_clk),
      .pixel_clk(pixel_clk),
      .rst(rst),
      .pixel_rst(rst),
      .enable_i(enable),
      .pixel_address_cpu_i(cpu_address),
      .pixel_write_data_cpu_i(cpu_data),
      .pixel_read_data_cpu_o(),
      .pixel_write_enable_cpu_i(cpu_write),
      .pixel_read_enable_cpu_i(1'b0),
      .tmds_symbols_o()
  );
  // Observe the assembled display path, including the single shared font ROM.
  assign x = dut.x;
  assign y = dut.y;
  assign active_video = dut.active_video;
  assign hor_state = dut.hor_state;
  assign ver_state = dut.ver_state;
  assign display_address = dut.generator_address;
  assign display_data = dut.generator_data;
  assign display_read = dut.generator_read;
  assign rgb = dut.rgb;

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
    expected_rgb = 0;
    if (active_video) begin
      screen_x = int'(x) - int'(OFFSET);
      cell_data = cell_value(screen_x / 8, int'(y) / 16);
      glyph_address = int'(cell_data.char_code) * 16 + int'(y) % 16;
      if (reference_font[glyph_address][7-screen_x%8])
        expected_rgb = cell_data.fg_col == 4'h1 ? 24'h0000AA : 24'h00AA00;
      else expected_rgb = cell_data.bg_col == 4'h4 ? 24'hAA0000 : 24'hFFFFFF;
    end
    assert (rgb == expected_rgb)
    else $fatal(1, "Pixel (%0d,%0d): got %h expected %h", x, y, rgb, expected_rgb);
    assert (display_read == (x < 640 && y < 480 && x[2:0] == 0))
    else $fatal(1, "Unexpected character read");
    if (display_read) begin
      assert (int'(display_address.x_pos) == int'(x)/8
          && int'(display_address.y_pos) == int'(y)/16)
      else $fatal(1, "Wrong cell address");
      requests++;
    end
  endtask

  initial begin
    $readmemh("rtl/peripherals/hdmi/fonts/NICER40C.hex", reference_font);
    // Initialize using the independent CPU clock, keeping the display reset.
    @(negedge cpu_clk);
    for (int row = 0; row < 30; row++) begin
      for (int column = 0; column < 80; column++) begin
        cpu_address.x_pos = 7'(column);
        cpu_address.y_pos = 5'(row);
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
