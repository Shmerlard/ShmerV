// Reference encoding equations: Project F / Will Green (2019, MIT).
// Attribution and license: docs/third-party.md.
module hdmi_tmds_encoder_tb;
  bit clk = 0;
  logic rst = 1;
  logic [7:0] color = 0;
  logic active_video = 0;
  logic [1:0] control = 0;
  logic [9:0] symbol;
  int reference_disparity = 0;
  bit [4:0] branches = 0;
  hdmi_tmds_encoder dut (
      .clk(clk),
      .rst(rst),
      .color_i(color),
      .active_video_i(active_video),
      .control_i(control),
      .symbol_o(symbol)
  );
  always #5 clk = ~clk;

  function automatic logic [9:0] control_symbol(input logic [1:0] c);
    case (c)
      0: return 10'b1101010100;
      1: return 10'b0010101011;
      2: return 10'b0101010100;
      3: return 10'b1010101011;
    endcase
  endfunction

  task automatic check_cycle;
    logic [8:0] q;
    logic [7:0] recovered, payload;
    logic [9:0] expected;
    int ones, balance;
    @(posedge clk);
    if (rst || !active_video) begin
      expected = rst ? control_symbol(0) : control_symbol(control);
      reference_disparity = 0;
    end else begin
      ones = 0;
      for (int i = 0; i < 8; i++) ones += int'(color[i]);
      q[8] = !(ones > 4 || (ones == 4 && !color[0]));
      q[0] = color[0];
      for (int i = 1; i < 8; i++) q[i] = q[8] ? (q[i-1] ^ color[i]) : (q[i-1] ~^ color[i]);
      ones = 0;
      for (int i = 0; i < 8; i++) ones += int'(q[i]);
      balance = 2 * ones - 8;
      if (reference_disparity == 0 || balance == 0) begin
        if (q[8]) begin
          expected = {2'b01, q[7:0]};
          reference_disparity += balance;
          branches[0] = 1;
        end else begin
          expected = {2'b10, ~q[7:0]};
          reference_disparity -= balance;
          branches[1] = 1;
        end
      end else if ((reference_disparity > 0 && balance > 0) ||
                   (reference_disparity < 0 && balance < 0)) begin
        expected = {1'b1, q[8], ~q[7:0]};
        reference_disparity += 2 * int'(q[8]) - balance;
        branches[2] = 1;
      end else begin
        expected = {1'b0, q[8], q[7:0]};
        reference_disparity += balance - 2 * int'(!q[8]);
        branches[3] = 1;
      end
    end
    #1;
    assert (symbol == expected)
    else $fatal(1, "TMDS mismatch for color %h", color);
    assert (int'(dut.running_disparity) == reference_disparity)
    else $fatal(1, "Running disparity mismatch");
    assert (reference_disparity >= -8 && reference_disparity <= 8)
    else $fatal(1, "Unbounded disparity");
    if (!rst && active_video) begin
      payload = symbol[9] ? ~symbol[7:0] : symbol[7:0];
      recovered[0] = payload[0];
      for (int i = 1; i < 8; i++) recovered[i] = payload[i] ^ payload[i-1] ^ !symbol[8];
      assert (recovered == color)
      else $fatal(1, "Color round-trip failed");
      branches[4] = 1;
    end
    @(negedge clk);
  endtask

  initial begin
    check_cycle();
    rst = 0;
    for (int c = 0; c < 4; c++) begin
      control = 2'(c);
      check_cycle();
    end
    // All two-byte sequences exercise history-dependent encoding decisions.
    for (int first = 0; first < 256; first++) begin
      for (int second = 0; second < 256; second++) begin
        active_video = 0;
        check_cycle();
        active_video = 1;
        color = 8'(first);
        check_cycle();
        color = 8'(second);
        check_cycle();
      end
    end
    // Long runs verify cumulative bias across many pixels.
    for (int value = 0; value < 256; value++) begin
      color = 8'(value);
      repeat (32) check_cycle();
    end
    rst = 1;
    check_cycle();
    rst = 0;
    check_cycle();
    active_video = 0;
    check_cycle();
    assert (&branches)
    else $fatal(1, "Encoding branches not covered");
    $display("PASS: TMDS control symbols, exhaustive byte pairs, decode, disparity, reset");
    $finish;
  end
endmodule
