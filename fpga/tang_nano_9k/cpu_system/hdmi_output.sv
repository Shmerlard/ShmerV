module hdmi_output (
    input wire pixel_clk,
    input wire serializer_clk,
    input wire reset,
    input wire [9:0] symbols [0:2],
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n
);
  wire serial_clock;
  wire [2:0] serial_data;
  hdmi_serializer clock_serializer (
      .pixel_clk(pixel_clk), .serializer_clk(serializer_clk),
      .reset(reset), .symbol(10'b1111100000), .serial(serial_clock)
  );
  ELVDS_OBUF clock_buffer (
      .I(serial_clock), .O(tmds_clk_p), .OB(tmds_clk_n)
  );
  for (genvar channel = 0; channel < 3; channel++) begin : data_channels
    hdmi_serializer data_serializer (
        .pixel_clk(pixel_clk), .serializer_clk(serializer_clk),
        .reset(reset), .symbol(symbols[channel]), .serial(serial_data[channel])
    );
    ELVDS_OBUF data_buffer (
        .I(serial_data[channel]), .O(tmds_d_p[channel]), .OB(tmds_d_n[channel])
    );
  end
endmodule
