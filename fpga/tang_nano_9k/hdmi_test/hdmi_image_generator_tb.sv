module hdmi_image_generator_tb;
  bit   clk = 0;
  logic rst = 1;
  logic [9:0] x = 0, y = 0;
  logic active_video = 0, hsync = 1, vsync = 1;
  logic [7:0] hue = 0;
  logic [7:0] red, green, blue;
  logic active_video_o, hsync_o, vsync_o;
  logic [3:0] indices[0:76799];
  logic [23:0] palette[0:15];
  logic [7:0] hue_red[0:4095], hue_green[0:4095], hue_blue[0:4095];
  logic [23:0] pending_rgb = 0;
  logic pending_active = 0, pending_hsync = 1, pending_vsync = 1;
  hdmi_image_generator #(
      .PIXEL_INIT_FILE("fpga/tang_nano_9k/hdmi_test/images/shmerv_pixels.hex"),
      .HUE_PALETTE_PREFIX("fpga/tang_nano_9k/hdmi_test/images/shmerv")
  ) dut (
      .*
  );
  always #5 clk = ~clk;
  task automatic check_pixel;
    logic [23:0] expected;
    int palette_address;
    expected = 24'd0;
    if (active_video && !rst) begin
      palette_address = int'(hue) * 16 + int'(indices[(int'(y)/2)*320+int'(x)/2]);
      expected = {hue_red[palette_address], hue_green[palette_address], hue_blue[palette_address]};
    end
    @(posedge clk);
    #1;
    assert ({red, green, blue} == (rst ? 24'd0 : pending_rgb))
    else $fatal(1, "Image pipeline mismatch at %d,%d", x, y);
    assert (active_video_o == (pending_active && !rst) &&
            hsync_o == (rst ? 1'b1 : pending_hsync) && vsync_o == (rst ? 1'b1 : pending_vsync))
    else $fatal(1, "Image control alignment mismatch");
    pending_rgb = expected;
    pending_active = active_video && !rst;
    pending_hsync = rst ? 1'b1 : hsync;
    pending_vsync = rst ? 1'b1 : vsync;
    @(negedge clk);
  endtask
  initial begin
    $readmemh("fpga/tang_nano_9k/hdmi_test/images/shmerv_pixels.hex", indices);
    $readmemh("fpga/tang_nano_9k/hdmi_test/images/shmerv_palette.hex", palette);
    $readmemh("fpga/tang_nano_9k/hdmi_test/images/shmerv_hue_red.hex", hue_red);
    $readmemh("fpga/tang_nano_9k/hdmi_test/images/shmerv_hue_green.hex", hue_green);
    $readmemh("fpga/tang_nano_9k/hdmi_test/images/shmerv_hue_blue.hex", hue_blue);
    for (int i = 0; i < 16; i++) begin
      assert ({hue_red[i], hue_green[i], hue_blue[i]} == palette[i])
      else $fatal(1, "Hue zero does not preserve original palette");
    end
    check_pixel();
    rst = 0;
    for (int row = 0; row < 525; row++) begin
      for (int column = 0; column < 800; column++) begin
        x = 10'(column);
        y = 10'(row);
        active_video = column < 640 && row < 480;
        hsync = !(column >= 656 && column < 752);
        vsync = !(row >= 490 && row < 492);
        check_pixel();
      end
    end
    x = 10'd639;
    y = 10'd479;
    active_video = 1;
    check_pixel();
    rst = 1;
    check_pixel();
    rst = 0;
    x   = 0;
    y   = 0;
    check_pixel();
    // Exercise every palette entry at every hue, changing hue each cycle.
    for (int color_index = 0; color_index < 16; color_index++) begin
      int location;
      location = -1;
      for (int i = 0; i < 76800; i++) if (int'(indices[i]) == color_index) location = i;
      assert (location >= 0)
      else $fatal(1, "Unused palette entry in image test");
      x = 10'((location % 320) * 2);
      y = 10'((location / 320) * 2);
      for (int amount = 0; amount < 256; amount++) begin
        hue = 8'(amount);
        check_pixel();
      end
      hue = 0;
      check_pixel();
    end
    active_video = 0;
    hue = 120;
    check_pixel();
    check_pixel();
    $display(
        "PASS: all scaled image pixels, 256 hue palettes, two-stage alignment, original colors, reset");
    $finish;
  end
endmodule
