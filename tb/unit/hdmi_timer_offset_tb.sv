module hdmi_timer_offset_tb;
  import hdmi_types::*;
  bit clk = 0;
  logic rst = 1;
  hdmi_horizontal_state_t hor_state[0:2];
  hdmi_vertical_state_t ver_state[0:2];
  logic [9:0] x[0:2], y[0:2];
  logic active_video[0:2];
  localparam int OFFSETS[0:2] = '{0, 5, 7};

  for (genvar i = 0; i < 3; i++) begin : timers
    hdmi_timer #(
        .VIDEO_X_OFFSET_PIXELS(3'(OFFSETS[i]))
    ) dut (
        .clk(clk),
        .rst(rst),
        .hor_state_o(hor_state[i]),
        .ver_state_o(ver_state[i]),
        .scan_pixel_x_o(x[i]),
        .scan_pixel_y_o(y[i]),
        .active_video_o(active_video[i])
    );
  end
  always #5 clk = ~clk;

  task automatic check_timing(input int position);
    int delayed_position, delayed_x, delayed_y;
    hdmi_horizontal_state_t expected_h;
    hdmi_vertical_state_t   expected_v;
    for (int i = 0; i < 3; i++) begin
      // Reference: delay the entire unshifted 800×525 raster.
      delayed_position = (position + 800 * 525 - OFFSETS[i]) % (800 * 525);
      delayed_x = delayed_position % 800;
      delayed_y = delayed_position / 800;
      expected_h = delayed_x < 640 ? HDMI_HOR_ACTIVE :
                   delayed_x < 656 ? HDMI_HOR_FPORCH :
                   delayed_x < 752 ? HDMI_HOR_HSYNC : HDMI_HOR_BPORCH;
      expected_v = delayed_y < 480 ? HDMI_VER_ACTIVE :
                   delayed_y < 490 ? HDMI_VER_FPORCH :
                   delayed_y < 492 ? HDMI_VER_VSYNC : HDMI_VER_BPORCH;
      assert (int'(x[i]) == position % 800 && int'(y[i]) == position / 800)
      else $fatal(1, "Counter mismatch");
      assert (hor_state[i] == expected_h && ver_state[i] == expected_v)
      else $fatal(1, "Offset %0d: region mismatch at %0d", OFFSETS[i], position);
      assert (active_video[i] == (delayed_x < 640 && delayed_y < 480))
      else $fatal(1, "Active mismatch");
    end
  endtask

  initial begin
    @(negedge clk);
    check_timing(0);
    rst = 0;
    for (int position = 0; position < 800 * 525; position++) begin
      check_timing(position);
      @(negedge clk);
    end
    check_timing(0);
    repeat (1234) @(negedge clk);
    rst = 1;
    @(negedge clk);
    check_timing(0);
    $display("PASS: full-frame timing offsets 0, 5, 7, wrap and reset");
    $finish;
  end
endmodule
