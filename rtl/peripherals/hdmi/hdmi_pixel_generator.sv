module hdmi_pixel_generator (
    input logic [9:0] x,
    input logic [9:0] y,
    input logic active_video,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);
  // Low eight bits implement modulo 256, repeating the gradient.
  assign red   = active_video ? x[7:0] : 8'd0;
  assign green = active_video ? y[7:0] : 8'd0;
  assign blue  = 8'd0;
endmodule
