module hdmi_timer_module_tb;
  import hdmi_types::*;
  bit clk = 0;
  logic rst = 1;
  hdmi_horizontal_state_t hor_state;
  hdmi_vertical_state_t ver_state;
  logic [9:0] x, y;
  logic active_video;
  logic [7:0] red, green, blue;
  hdmi_timer dut (.*);
  hdmi_pixel_generator pixels (.*);
  always #5 clk = ~clk;

  task automatic check_position(input int x, input int y);
    hdmi_horizontal_state_t expected_h;
    hdmi_vertical_state_t   expected_v;
    expected_h = x < 640 ? HDMI_HOR_ACTIVE :
                 x < 656 ? HDMI_HOR_FPORCH :
                 x < 752 ? HDMI_HOR_HSYNC : HDMI_HOR_BPORCH;
    expected_v = y < 480 ? HDMI_VER_ACTIVE :
                 y < 490 ? HDMI_VER_FPORCH :
                 y < 492 ? HDMI_VER_VSYNC : HDMI_VER_BPORCH;
    assert (int'(dut.horizontal_counter) == x && int'(dut.vertical_counter) == y)
    else $fatal(1, "Counter mismatch at (%0d,%0d)", x, y);
    assert (hor_state == expected_h && ver_state == expected_v)
    else $fatal(1, "Region mismatch at (%0d,%0d)", x, y);
    assert (int'(hdmi_timer_module_tb.x) == x && int'(hdmi_timer_module_tb.y) == y)
    else $fatal(1, "Coordinate output mismatch");
    assert (active_video == (x < 640 && y < 480))
    else $fatal(1, "Active video mismatch at (%0d,%0d)", x, y);
    if (x < 640 && y < 480) begin
      assert (int'(red) == x % 256 && int'(green) == y % 256 && blue == 0)
      else $fatal(1, "Gradient mismatch at (%0d,%0d)", x, y);
    end else begin
      assert ({red, green, blue} == 24'd0)
      else $fatal(1, "Nonblack pixel outside active video");
    end
  endtask

  initial begin
    @(negedge clk);
    check_position(0, 0);
    rst = 0;
    // Check every position in a frame, including all region transitions.
    for (int y = 0; y < 525; y++) begin
      for (int x = 0; x < 800; x++) begin
        check_position(x, y);
        @(negedge clk);
      end
    end
    check_position(0, 0);
    repeat (1234) @(negedge clk);
    rst = 1;
    @(negedge clk);
    check_position(0, 0);
    @(negedge clk);
    check_position(0, 0);
    rst = 0;
    @(negedge clk);
    check_position(1, 0);
    $display("PASS: HDMI timing, coordinates, repeating gradient, blanking, and reset");
    $finish;
  end
endmodule
