// Encoding flow informed by Project F's TMDS encoder (Will Green, 2019, MIT).
// https://github.com/projf/display_controller/blob/master/rtl/tmds_encoder_dvi.v
// Rewritten here with a loop for transition reduction and symbol-based disparity.
// Attribution and license: docs/third-party.md.
module hdmi_tmds_encoder (
    input logic clk,
    input logic rst,
    input logic [7:0] color,
    input logic active_video,
    // During blanking: blue uses {vsync, hsync}; red and green use 2'b00.
    input logic [1:0] control,
    output logic [9:0] symbol
);
  logic [8:0] transition_word;
  logic [9:0] next_symbol;
  logic use_xnor;
  logic signed [4:0] running_disparity;
  logic signed [4:0] next_disparity;
  integer color_ones;
  integer word_balance;
  integer symbol_balance;

  always_comb begin
    // Stage 1: choose XOR or XNOR to reduce adjacent bit transitions.
    color_ones = $countones(color);
    use_xnor = (color_ones > 4) || ((color_ones == 4) && !color[0]);
    transition_word = '0;
    transition_word[0] = color[0];
    for (int bit_index = 1; bit_index < 8; bit_index++) begin
      transition_word[bit_index] = transition_word[bit_index-1] ^ color[bit_index] ^ use_xnor;
    end
    transition_word[8] = !use_xnor;
    word_balance = 2 * $countones(transition_word[7:0]) - 8;

    // Stage 2: invert the payload when needed to limit cumulative DC bias.
    if (running_disparity == 0 || word_balance == 0) begin
      next_symbol = {
        !transition_word[8],
        transition_word[8],
        transition_word[8] ? transition_word[7:0] : ~transition_word[7:0]
      };
    end else if ((running_disparity > 0 && word_balance > 0) ||
                 (running_disparity < 0 && word_balance < 0)) begin
      next_symbol = {1'b1, transition_word[8], ~transition_word[7:0]};
    end else begin
      next_symbol = {1'b0, transition_word[8], transition_word[7:0]};
    end

    // Include both prefix bits in the transmitted symbol's disparity.
    symbol_balance = 2 * $countones(next_symbol) - 10;
    next_disparity = 5'(int'(running_disparity) + symbol_balance);
    if (!active_video) begin
      case (control)
        2'b00: next_symbol = 10'b1101010100;
        2'b01: next_symbol = 10'b0010101011;
        2'b10: next_symbol = 10'b0101010100;
        2'b11: next_symbol = 10'b1010101011;
      endcase
      next_disparity = '0;
    end
  end

  // One pixel-clock latency. Reset and every blanking symbol clear DC bias.
  always_ff @(posedge clk) begin
    if (rst) begin
      symbol <= 10'b1101010100;
      running_disparity <= '0;
    end else begin
      symbol <= next_symbol;
      running_disparity <= next_disparity;
    end
  end
endmodule
