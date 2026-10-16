module hdmi_blink_module #(
    parameter int unsigned CPU_CLOCK_HZ = 843_750,
    parameter int unsigned BLINK_INTERVAL_MS = 500
) (
    input  logic cpu_clk,
    input  logic rst,
    input  logic cursor_enable_i,
    input  logic cursor_blink_i,
    output logic cursor_visible_o
);

  localparam int unsigned CYCLES_PER_PERIOD = (CPU_CLOCK_HZ * BLINK_INTERVAL_MS) / 1000;
  localparam int unsigned CYCLES_WIDTH = (CYCLES_PER_PERIOD > 1) ? $clog2(CYCLES_PER_PERIOD) : 1;

  logic [CYCLES_WIDTH-1:0] blink_counter;
  logic blink_visible;

  always_ff @(posedge cpu_clk) begin
    if (rst) begin
      blink_counter <= 0;
      blink_visible <= 0;
    end else if (blink_counter == CYCLES_WIDTH'(CYCLES_PER_PERIOD - 1)) begin
      // Each visible/hidden interval lasts BLINK_INTERVAL_MS.
      blink_counter <= 0;
      blink_visible <= ~blink_visible;
    end else begin
      blink_counter <= blink_counter + 1;
    end
  end

  always_comb begin
    cursor_visible_o = 0;
    if (cursor_enable_i) begin
      if (~cursor_blink_i) cursor_visible_o = 1;
      else begin
        cursor_visible_o = blink_visible;
      end
    end
  end

endmodule
