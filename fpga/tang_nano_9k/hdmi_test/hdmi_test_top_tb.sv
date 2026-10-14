`timescale 1ns / 1ps
// Simulation only; exclude from FPGA sources. Use Gowin's gw1n/prim_sim.v.
module hdmi_test_top_tb;
  logic clk = 0;
  logic reset_button_n_i = 0;
  logic animation_button_n_i = 0;
  wire tmds_clk_p, tmds_clk_n;
  wire [2:0] tmds_d_p, tmds_d_n;
  GSR GSR (.GSRI(1'b1));
  hdmi_test_top #(
      .PIXEL_INIT_FILE("fpga/tang_nano_9k/hdmi_test/images/shmerv_pixels.hex"),
      .HUE_PALETTE_PREFIX("fpga/tang_nano_9k/hdmi_test/images/shmerv")
  ) dut (
      .*
  );
  always #18.518519 clk = ~clk;

  function automatic logic [7:0] decode(input logic [9:0] word);
    logic [7:0] payload, value;
    payload  = word[9] ? ~word[7:0] : word[7:0];
    value[0] = payload[0];
    for (int i = 1; i < 8; i++) value[i] = payload[i] ^ payload[i-1] ^ !word[8];
    return value;
  endfunction

  initial begin : timeout
    #200000;
    $fatal(1, "Timeout waiting for HDMI clocks/output");
  end

  initial begin : checks
    realtime start_time, period;
    logic [9:0] words[0:2];
    logic [23:0] expected_rgb;
    int image_x;
    #200;
    reset_button_n_i = 1;
    wait (dut.pll_locked);
    wait (!dut.pixel_reset);
    @(posedge dut.pixel_clk);
    start_time = $realtime;
    @(posedge dut.pixel_clk);
    period = $realtime - start_time;
    assert (period > 39.5 && period < 39.9)
    else $fatal(1, "Pixel period %f", period);
    @(posedge dut.serializer_clk);
    start_time = $realtime;
    @(posedge dut.serializer_clk);
    period = $realtime - start_time;
    assert (period > 7.8 && period < 8.1)
    else $fatal(1, "Fast period %f", period);
    repeat (20) @(posedge dut.pixel_clk);

    // Clock-lane falling edge marks data bit 0; all OSER10s share latency.
    for (int pixel = 0; pixel < 100; pixel++) begin
      @(negedge tmds_clk_p);
      #0.1;
      for (int bit_index = 0; bit_index < 10; bit_index++) begin
        for (int channel = 0; channel < 3; channel++) words[channel][bit_index] = tmds_d_p[channel];
        assert (tmds_d_n == ~tmds_d_p && tmds_clk_n == ~tmds_clk_p)
        else $fatal(1, "Differential outputs not complementary");
        if (bit_index < 9) begin
          @(dut.serializer_clk);
          #0.1;
        end
      end
      // At the end of bit 9, the timer is seven positions ahead of the
      // transmitted pixel (ROM, encoder, and vendor OSER10 pipeline/phase).
      image_x = int'(dut.x) - 7;
      expected_rgb = {
        dut.pixels.hue_red_rom[dut.pixels.image_rom[image_x/2]],
        dut.pixels.hue_green_rom[dut.pixels.image_rom[image_x/2]],
        dut.pixels.hue_blue_rom[dut.pixels.image_rom[image_x/2]]
      };
      assert ({decode(words[2]), decode(words[1]), decode(words[0])} == expected_rgb)
      else
        $fatal(
            1,
            "Serialized image mismatch at source x=%d: actual=%h expected=%h timer=%d",
            image_x,
            {
              decode(words[2]), decode(words[1]), decode(words[0])
            },
            expected_rgb,
            dut.x
        );
    end
    assert (dut.hold_original && dut.hue == 0)
    else $fatal(1, "Held S2 did not select original palette");
    animation_button_n_i = 1;
    repeat (4) @(negedge dut.pixel_clk);
    assert (!dut.hold_original)
    else $fatal(1, "Released S2 did not resume animation");
    animation_button_n_i = 0;
    repeat (4) @(negedge dut.pixel_clk);
    assert (dut.hold_original && dut.hue == 0)
    else $fatal(1, "S2 synchronization failed");
    reset_button_n_i = 0;
    #1;
    assert (dut.pixel_reset)
    else $fatal(1, "Reset did not assert immediately");
    #200;
    reset_button_n_i = 1;
    wait (dut.pll_locked);
    wait (!dut.pixel_reset);
    #1;
    assert (dut.x == 0 && dut.y == 0)
    else $fatal(1, "Counters did not restart at origin");
    $display(
        "PASS: vendor PLL/CLKDIV periods, OSER10 bit order, RGB lanes, differential outputs, reset");
    $finish;
  end
endmodule
