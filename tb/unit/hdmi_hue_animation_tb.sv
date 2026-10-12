module hdmi_hue_animation_tb;
  bit clk = 0;
  logic rst = 1, frame_tick = 0, hold_original = 0;
  logic [7:0] hue;
  hdmi_hue_animation dut (.*);
  always #5 clk = ~clk;
  task automatic step;
    @(posedge clk);
    #1;
    @(negedge clk);
  endtask
  initial begin
    step();
    assert (hue == 0) else $fatal;
    rst = 0;
    repeat (10) step();
    assert (hue == 0) else $fatal(1, "Changed without frame tick");
    for (int frame_number = 1; frame_number <= 1440; frame_number++) begin
      int phase, expected;
      frame_tick = 1;
      step();
      frame_tick = 0;
      phase = frame_number;
      expected = ((phase * 16) / 45) % 256;
      assert (int'(hue) == expected) else $fatal(1, "Hue phase mismatch");
      step();
      if (frame_number == 73) begin
        hold_original = 1;
        #1;
        assert (hue == 0) else $fatal(1, "Hold did not restore original");
        frame_tick = 1;
        repeat (300) step();
        frame_tick = 0;
        hold_original = 0;
        #1;
        assert (int'(hue) == expected) else $fatal(1, "Phase did not pause");
      end
    end
    frame_tick = 1;
    step();
    rst = 1;
    step();
    assert (hue == 0) else $fatal(1, "Reset did not clear hue");
    $display("PASS: 720-frame hue cycle, hold restores original/pauses, reset");
    $finish;
  end
endmodule
