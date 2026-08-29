module smoke_tb;
  logic a;
  logic b;
  logic y;

  smoke dut (
      .a(a),
      .b(b),
      .y(y)
  );

  initial begin
    a = 1'b0;
    b = 1'b0;
    #1;
    assert (y == 1'b0);

    a = 1'b1;
    b = 1'b1;
    #1;
    assert (y == 1'b1);

    $display("smoke test passed");
    $finish;
  end
endmodule

