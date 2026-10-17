module cdc_handshake_case #(
    parameter int WIDTH = 12,
    parameter int SRC_HALF = 5,
    parameter int DST_HALF = 7
) (
    output bit done = 0
);
  bit src_clk = 0, dst_clk = 0;
  logic src_rst = 1, dst_rst = 1;
  logic [WIDTH-1:0] data_i = '0, data_o;
  logic [WIDTH-1:0] expected[$];
  logic [WIDTH-1:0] previous_hold, previous_output;
  bit previous_busy = 0, previous_ack = 0;
  int received = 0;

  cdc_handshake #(.WIDTH(WIDTH)) dut (.*);
  always #(SRC_HALF) src_clk = ~src_clk;
  always #(DST_HALF) dst_clk = ~dst_clk;

  // Record the complete word accepted by each source-side transaction.
  always @(posedge src_clk) begin
    if (src_rst) expected.delete();
    else if (dut.state == dut.IDLE) expected.push_back(data_i);
  end

  always @(negedge src_clk) begin
    if (src_rst) previous_busy = 0;
    else begin
      if (previous_busy)
        assert (dut.cdc_hs_hold == previous_hold)
        else $fatal(1, "WIDTH=%0d: snapshot changed during handshake", WIDTH);
      previous_hold = dut.cdc_hs_hold;
      previous_busy = dut.state != dut.IDLE;
    end
  end

  // Every acknowledgement must correspond to exactly one accepted word.
  always @(negedge dst_clk) begin
    if (dst_rst) begin
      previous_ack = 0;
      previous_output = '0;
      received = 0;
    end else begin
      if (dut.ack && !previous_ack) begin
        assert (expected.size() > 0)
        else $fatal(1, "WIDTH=%0d: unexpected reception", WIDTH);
        assert (data_o == expected.pop_front())
        else $fatal(1, "WIDTH=%0d: corrupted or reordered word", WIDTH);
        received++;
      end else begin
        assert (data_o == previous_output)
        else $fatal(1, "WIDTH=%0d: output changed without reception", WIDTH);
      end
      previous_ack = dut.ack;
      previous_output = data_o;
    end
  end

  task automatic release_reset;
    repeat (4) @(negedge dst_clk);
    dst_rst = 0;
    @(negedge src_clk);
    src_rst = 0;
  endtask

  initial begin
    release_reset();
    // Update faster than a handshake: intermediate values may be skipped.
    for (int i = 0; i < 40; i++) begin
      @(negedge src_clk);
      data_i = WIDTH'(i ^ (i << 4));
    end
    @(negedge src_clk);
    data_i = '1;
    repeat (100) @(negedge src_clk);
    assert (data_o == '1 && received > 1)
    else $fatal(1, "WIDTH=%0d: latest value did not arrive", WIDTH);

    // Coordinated reset aborts any transaction and restarts both domains.
    src_rst = 1;
    dst_rst = 1;
    data_i  = '0;
    repeat (4) @(negedge src_clk);
    repeat (4) @(negedge dst_clk);
    assert (data_o == '0)
    else $fatal(1, "Destination reset failed");
    release_reset();
    @(negedge src_clk);
    data_i = WIDTH'(1);
    repeat (100) @(negedge src_clk);
    assert (data_o == WIDTH'(1) && received > 0)
    else $fatal(1, "WIDTH=%0d: transfer after reset failed", WIDTH);
    done = 1;
  end
endmodule

module cdc_handshake_tb;
  wire [2:0] done;
  cdc_handshake_case #(
      .WIDTH(1),
      .SRC_HALF(5),
      .DST_HALF(13)
  ) bit_case (
      done[0]
  );
  cdc_handshake_case #(
      .WIDTH(12),
      .SRC_HALF(19),
      .DST_HALF(7)
  ) cursor_case (
      done[1]
  );
  cdc_handshake_case #(
      .WIDTH(32),
      .SRC_HALF(7),
      .DST_HALF(11)
  ) word_case (
      done[2]
  );

  initial begin
    wait (&done);
    $display("PASS: handshake widths 1/12/32, clock ratios, changing input, reset");
    $finish;
  end
  initial begin
    #100000;
    $fatal(1, "Handshake timeout");
  end
endmodule
