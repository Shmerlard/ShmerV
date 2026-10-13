import hdmi_types::*;

module hdmi_timer (
    input logic clk,
    input logic rst,
    output hdmi_horizontal_state_t hor_state,
    output hdmi_vertical_state_t ver_state,
    output logic [9:0] x,
    output logic [9:0] y,
    output logic active_video
);

  logic [9:0] horizontal_counter;
  logic [9:0] vertical_counter;

  assign x = horizontal_counter;
  assign y = vertical_counter;
  assign active_video = (hor_state == HDMI_HOR_ACTIVE) && (ver_state == HDMI_VER_ACTIVE);

  // Both counters use the pixel clock. Vertical advances once per line.
  always_ff @(posedge clk) begin
    if (rst) begin
      horizontal_counter <= 10'd0;
      vertical_counter   <= 10'd0;
    end else if (horizontal_counter == 10'd799) begin
      horizontal_counter <= 10'd0;
      if (vertical_counter == 10'd524) vertical_counter <= 10'd0;
      else vertical_counter <= vertical_counter + 10'd1;
    end else begin
      horizontal_counter <= horizontal_counter + 10'd1;
    end
  end

  always_comb begin
    if (horizontal_counter < 640) hor_state = HDMI_HOR_ACTIVE;
    else if (horizontal_counter < 656) hor_state = HDMI_HOR_FPORCH;
    else if (horizontal_counter < 752) hor_state = HDMI_HOR_HSYNC;
    else hor_state = HDMI_HOR_BPORCH;
  end

  always_comb begin
    if (vertical_counter < 480) ver_state = HDMI_VER_ACTIVE;
    else if (vertical_counter < 490) ver_state = HDMI_VER_FPORCH;
    else if (vertical_counter < 492) ver_state = HDMI_VER_VSYNC;
    else ver_state = HDMI_VER_BPORCH;
  end

endmodule
