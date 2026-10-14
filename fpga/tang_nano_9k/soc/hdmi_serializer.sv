module hdmi_serializer (
    input wire pixel_clk,
    input wire serializer_clk,
    input wire reset,
    input wire [9:0] symbol,
    output wire serial
);
  // Least significant bit first, two bits per fast-clock cycle.
  OSER10 serializer (
      .D0(symbol[0]), .D1(symbol[1]), .D2(symbol[2]), .D3(symbol[3]),
      .D4(symbol[4]), .D5(symbol[5]), .D6(symbol[6]), .D7(symbol[7]),
      .D8(symbol[8]), .D9(symbol[9]), .PCLK(pixel_clk),
      .FCLK(serializer_clk), .RESET(reset), .Q(serial)
  );
endmodule
