timeunit 1ns / 1ps;

module memory_tb;

  logic clk;
  logic [31:0] addr_rd_a;
  logic [31:0] addr_rd_b;
  logic [31:0] addr_wr;
  logic wr_en;
  logic [31:0] wr_data_i;
  logic [31:0] data_rd_a;
  logic [31:0] data_rd_b;

  memory #(
      .MEM_WORDS(1024)
  ) dut (
      .clk      (clk),
      .addr_rd_a(addr_rd_a),
      .addr_rd_b(addr_rd_b),
      .addr_wr  (addr_wr),
      .wr_en    (wr_en),
      .wr_data_i(wr_data_i),
      .data_rd_a(data_rd_a),
      .data_rd_b(data_rd_b)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    addr_rd_a = '0;
    addr_rd_b = '0;
    addr_wr = '0;
    wr_en = 1'b0;
    wr_data_i = '0;

    // Preload memory
    dut.mem[0] = 32'h1234_5678;
    dut.mem[1] = 32'hDEAD_BEEF;
    dut.mem[7] = 32'hCAFE_BABE;

    // Read word 0
    addr_rd_a = 32'h0000_0000;
    @(posedge clk);
    #1;
    assert (data_rd_a == 32'h1234_5678)
    else $fatal(1, "Expected 12345678, got %h", data_rd_a);

    // Change address -- output should not change until next clock
    addr_rd_a = 32'h0000_0004;
    #1;
    assert (data_rd_a == 32'h1234_5678)
    else $fatal(1, "Memory read changed asynchronously");

    @(posedge clk);
    #1;
    assert (data_rd_a == 32'hDEAD_BEEF)
    else $fatal(1, "Expected DEADBEEF, got %h", data_rd_a);

    // Check address-to-word indexing: address 0x1C -> mem[7]
    addr_rd_a = 32'h0000_001C;
    @(posedge clk);
    #1;
    assert (data_rd_a == 32'hCAFE_BABE)
    else $fatal(1, "Expected CAFEBABE, got %h", data_rd_a);

    // Write word 2 using byte address 0x08.
    addr_wr = 32'h0000_0008;
    wr_data_i = 32'hAABB_CCDD;
    wr_en = 1'b1;
    @(posedge clk);
    #1;
    wr_en = 1'b0;

    // Read the written word through Port B.
    addr_rd_b = 32'h0000_0008;
    @(posedge clk);
    #1;
    assert (data_rd_b == 32'hAABB_CCDD)
    else $fatal(1, "Expected AABBCCDD from Port B, got %h", data_rd_b);

    $display("memory tests passed");
    $finish;
  end

endmodule
