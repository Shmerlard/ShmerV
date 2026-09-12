module smoke_tb;
  logic a_i;
  logic b_i;
  logic y_o;

  smoke dut (
      .a_i(a_i),
      .b_i(b_i),
      .y_o(y_o)
  );

  initial begin
    $dumpfile("build/tests/smoke/waveform.fst");
    $dumpvars(0, smoke_tb);

    a_i = 1'b0;
    b_i = 1'b0;
    #1;
    assert (y_o == 1'b0);

    a_i = 1'b1;
    b_i = 1'b1;
    #1;
    assert (y_o == 1'b1);

    $display("smoke test passed");
    $finish;
  end
endmodule
