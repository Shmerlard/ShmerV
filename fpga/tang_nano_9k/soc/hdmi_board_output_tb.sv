`timescale 1ns / 1ps
module hdmi_board_output_tb;
  logic clk = 0, reset = 1;
  wire pixel_clk, serializer_clk, locked;
  wire tmds_clk_p, tmds_clk_n;
  wire [2:0] tmds_d_p, tmds_d_n;
  wire [9:0] symbols[0:2];
  assign symbols[0] = 10'b1101010100;
  assign symbols[1] = 10'b0010101011;
  assign symbols[2] = 10'b1010101011;
  GSR GSR (.GSRI(1'b1));
  hdmi_clocks clocks (.*);
  hdmi_output outputs (.*);
  always #18.518519 clk = ~clk;
  initial begin
    #200000;
    $fatal(1, "HDMI output timeout");
  end
  initial begin
    realtime start_time, period;
    logic [9:0] words[0:2];
    #200;
    reset = 0;
    wait (locked);
    repeat (20) @(posedge pixel_clk);
    start_time = $realtime;
    @(posedge pixel_clk);
    period = $realtime - start_time;
    assert (period > 39.5 && period < 39.9)
    else $fatal(1, "Pixel clock period");
    @(posedge serializer_clk);
    start_time = $realtime;
    @(posedge serializer_clk);
    period = $realtime - start_time;
    assert (period > 7.8 && period < 8.1)
    else $fatal(1, "Serializer clock period");
    for (int pixel = 0; pixel < 20; pixel++) begin
      @(negedge tmds_clk_p);
      #0.1;
      for (int bit_index = 0; bit_index < 10; bit_index++) begin
        for (int channel = 0; channel < 3; channel++) words[channel][bit_index] = tmds_d_p[channel];
        assert (tmds_d_n == ~tmds_d_p && tmds_clk_n == ~tmds_clk_p)
        else $fatal(1, "Differential polarity");
        if (bit_index < 9) begin
          @(serializer_clk);
          #0.1;
        end
      end
      for (int channel = 0; channel < 3; channel++)
      assert (words[channel] == symbols[channel])
      else $fatal(1, "Serializer bit order");
    end
    $display("PASS: HDMI PLL/divider, serializers and differential buffers");
    $finish;
  end
endmodule
