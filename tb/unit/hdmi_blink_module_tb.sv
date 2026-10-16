module hdmi_blink_module_tb;
  bit   cpu_clk = 0;
  logic rst = 1;
  logic cursor_enable_i = 1, cursor_blink_i = 1;
  logic cursor_visible_o;
  // Five clocks per visibility interval; exercise a non-power-of-two count.
  hdmi_blink_module #(
      .CPU_CLOCK_HZ(1000),
      .BLINK_INTERVAL_MS(5)
  ) dut (
      .*
  );
  always #5 cpu_clk = ~cpu_clk;

  initial begin
    repeat (2) @(negedge cpu_clk);
    assert (!cursor_visible_o)
    else $fatal(1, "Reset visibility");
    rst = 0;
    for (int cycle = 1; cycle <= 30; cycle++) begin
      @(negedge cpu_clk);
      assert (cursor_visible_o == ((cycle / 5) % 2 != 0))
      else $fatal(1, "Wrong blink interval at cycle %0d", cycle);
    end
    cursor_blink_i = 0;
    #1;
    assert (cursor_visible_o)
    else $fatal(1, "Steady cursor must be visible");
    cursor_enable_i = 0;
    #1;
    assert (!cursor_visible_o)
    else $fatal(1, "Disable must hide cursor");
    cursor_blink_i = 1;
    repeat (7) @(negedge cpu_clk);
    assert (!cursor_visible_o)
    else $fatal(1, "Disabled blinking cursor visible");
    rst = 1;
    @(negedge cpu_clk);
    cursor_enable_i = 1;
    #1;
    assert (!cursor_visible_o)
    else $fatal(1, "Reset must restart blink phase");
    $display("PASS: exact blink intervals, steady/disabled cursor, reset phase");
    $finish;
  end
endmodule
