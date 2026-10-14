// Clock arrangement already validated by the standalone HDMI example.
// Primitive references: docs/third-party.md.
module hdmi_clocks (
    input wire clk,
    input wire reset,
    output wire serializer_clk,
    output wire pixel_clk,
    output wire locked
);
  // 27 MHz * 14 / 3 = 126 MHz; VCO = 1008 MHz.
  rPLL #(
      .FCLKIN("27"), .IDIV_SEL(2), .FBDIV_SEL(13), .ODIV_SEL(8),
      .DYN_IDIV_SEL("false"), .DYN_FBDIV_SEL("false"),
      .DYN_ODIV_SEL("false"), .DYN_DA_EN("false"),
      .PSDA_SEL("0000"), .DUTYDA_SEL("1000"),
      .CLKFB_SEL("internal"), .DEVICE("GW1NR-9C")
  ) pll (
      .CLKIN(clk), .RESET(reset), .RESET_P(1'b0), .CLKFB(1'b0),
      .FBDSEL(6'd0), .IDSEL(6'd0), .ODSEL(6'd0),
      .PSDA(4'd0), .DUTYDA(4'd0), .FDLY(4'd0),
      .CLKOUT(serializer_clk), .LOCK(locked),
      .CLKOUTP(), .CLKOUTD(), .CLKOUTD3()
  );
  CLKDIV #(.DIV_MODE("5"), .GSREN("false")) pixel_divider (
      .HCLKIN(serializer_clk), .RESETN(locked && !reset),
      .CALIB(1'b0), .CLKOUT(pixel_clk)
  );
endmodule
