module hdmi_hue_animation (
    input logic clk,
    input logic rst,
    input logic frame_tick,
    input logic hold_original,
    output logic [7:0] hue
);
  logic [7:0] phase;
  logic [5:0] fraction;
  // 16/45 steps per frame: 256 steps in 720 frames (12 seconds at 60 Hz).
  always_ff @(posedge clk) begin
    if (rst) begin
      phase <= 8'd0;
      fraction <= 6'd0;
    end else if (frame_tick && !hold_original) begin
      if (fraction >= 6'd29) begin
        fraction <= fraction - 6'd29;
        phase <= phase + 8'd1;
      end else fraction <= fraction + 6'd16;
    end
  end
  assign hue = hold_original ? 8'd0 : phase;
endmodule
