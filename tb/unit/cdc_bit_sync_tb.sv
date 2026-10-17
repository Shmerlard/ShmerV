module cdc_bit_sync_tb;
  bit dst_clk = 0;
  logic dst_rst = 1, data_i = 0, data_o;
  cdc_bit_sync dut (.*);

  task automatic edge_check(input bit expected);
    #7 dst_clk = 1;
    #1;
    assert (data_o == expected)
    else $fatal(1, "Unexpected synchronized bit");
    #7 dst_clk = 0;
  endtask

  initial begin
    edge_check(0);
    dst_rst = 0;
    data_i  = 1;
    #3;
    assert (!data_o)
    else $fatal(1, "Asynchronous input bypassed registers");
    edge_check(0);
    edge_check(1);
    data_i = 0;
    edge_check(1);
    edge_check(0);
    data_i = 1;
    edge_check(0);
    edge_check(1);
    dst_rst = 1;
    edge_check(0);
    dst_rst = 0;
    edge_check(0);
    edge_check(1);
    $display("PASS: bit synchronizer latency, transitions, reset");
    $finish;
  end
endmodule
