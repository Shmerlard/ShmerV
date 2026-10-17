module hdmi_module_tb;
  import hdmi_types::*;
  bit cpu_clk = 0;
  bit pixel_clk = 0;
  logic rst = 1, pixel_rst = 1;
  hdmi_access_target_t access_target_i = HDMI_TARGET_CTRL;
  logic [15:0] hdmi_write_data_i = 0, hdmi_read_data_o;
  logic [14:0] hdmi_address_i = 0;
  logic hdmi_write_enable_i = 0, hdmi_read_enable_i = 0;
  logic irq_o;
  logic [9:0] tmds_symbols_o[0:2];

  hdmi_module dut (.*);
  always #5 cpu_clk = ~cpu_clk;

  task automatic pixel_edge(input bit expected);
    #7 pixel_clk = 1;
    #1;
    assert (dut.renderer.enable_i == expected)
    else $fatal(1, "Unexpected pixel-domain enable: expected %b", expected);
    #7 pixel_clk = 0;
  endtask

  task automatic write_cursor_enable(input bit value);
    @(negedge cpu_clk);
    // Keep display enabled, disable blinking, and select cursor visibility.
    hdmi_write_data_i   = value ? 16'h18 : 16'h10;
    hdmi_write_enable_i = 1;
    @(negedge cpu_clk);
    hdmi_write_enable_i = 0;
    repeat (2) @(negedge cpu_clk);
  endtask

  task automatic cursor_pixel_edge(input bit expected);
    pixel_edge(1);
    assert (dut.renderer.cursor_visible_pixel == expected)
    else $fatal(1, "Unexpected synchronized cursor visibility: expected %b", expected);
  endtask

  task automatic write_enable(input bit value);
    @(negedge cpu_clk);
    hdmi_write_data_i   = value ? 16'h10 : 16'h00;
    hdmi_write_enable_i = 1;
    @(negedge cpu_clk);
    hdmi_write_enable_i = 0;
  endtask

  initial begin
    repeat (2) @(negedge cpu_clk);
    pixel_edge(0);
    rst = 0;
    pixel_rst = 0;
    // Controller reset enables display; it takes two pixel edges to arrive.
    pixel_edge(0);
    pixel_edge(1);
    write_enable(0);
    assert (dut.renderer.enable_i == 1)
    else $fatal(1, "CPU write bypassed pixel synchronizer");
    pixel_edge(1);
    pixel_edge(0);
    write_enable(1);
    pixel_edge(0);
    pixel_edge(1);
    // Pixel reset clears both stages even while CPU control stays enabled.
    pixel_rst = 1;
    pixel_edge(0);
    pixel_rst = 0;
    pixel_edge(0);
    pixel_edge(1);
    // CPU-side cursor controls must not bypass the two pixel registers.
    write_cursor_enable(0);
    cursor_pixel_edge(0);
    cursor_pixel_edge(0);
    write_cursor_enable(1);
    assert (!dut.renderer.cursor_visible_pixel)
    else $fatal(1, "Cursor enable bypassed pixel synchronizer");
    cursor_pixel_edge(0);
    cursor_pixel_edge(1);
    write_cursor_enable(0);
    cursor_pixel_edge(1);
    cursor_pixel_edge(0);
    write_cursor_enable(1);
    cursor_pixel_edge(0);
    cursor_pixel_edge(1);
    pixel_rst = 1;
    pixel_edge(0);
    assert (!dut.renderer.cursor_visible_pixel)
    else $fatal(1, "Pixel reset did not clear cursor visibility");
    pixel_rst = 0;
    pixel_edge(0);
    assert (!dut.renderer.cursor_visible_pixel)
    else $fatal(1, "Cursor visibility skipped a synchronization stage after reset");
    cursor_pixel_edge(1);
    $display("PASS: HDMI enable pixel-domain synchronization");
    $finish;
  end
endmodule
