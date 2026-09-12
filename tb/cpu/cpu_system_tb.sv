timeunit 1ns / 1ps;

module cpu_system_tb;
  logic clk = 1'b0;
  logic rst;
  integer cycles;
  logic [31:0] expected_address;
  logic [31:0] expected_value;
  string trace_file;

  cpu_system dut (
      .clk(clk),
      .rst(rst)
  );

  always #5ns clk = ~clk;

  initial begin
    if (!$value$plusargs("cycles=%d", cycles)) $fatal(1, "Missing +cycles");
    if (!$value$plusargs("expected_address=%h", expected_address))
      $fatal(1, "Missing +expected_address");
    if (!$value$plusargs("expected_value=%h", expected_value)) $fatal(1, "Missing +expected_value");
    if (!$value$plusargs("trace_file=%s", trace_file)) trace_file = "build/cpu_system.fst";

    $dumpfile(trace_file);
    $dumpvars(0, cpu_system_tb);

    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;

    repeat (cycles) @(posedge clk);
    #1ns;

    assert (dut.memory.memory_words[expected_address[11:2]] == expected_value)
    else
      $fatal(
          1,
          "Expected memory[%h] = %h, got %h",
          expected_address,
          expected_value,
          dut.memory.memory_words[expected_address[11:2]]
      );

    $display("cpu_system tests passed");
    $finish;
  end
endmodule
