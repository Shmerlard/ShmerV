timeunit 1ns / 1ps;

module program_counter_tb;

  logic        clk;
  logic        rst;
  logic        enable;
  logic [31:0] next_pc;
  logic [31:0] pc_out;

  program_counter dut (
      .clk     (clk),
      .rst     (rst),
      .enable  (enable),
      .next_pc (next_pc),
      .pc_out  (pc_out)
  );

  always #5 clk = ~clk;

  initial begin
    clk     = 0;
    rst     = 0;
    enable  = 0;
    next_pc = 32'h00000000;

    // Reset
    rst = 1;
    @(posedge clk);
    #1;
    assert (pc_out == 32'h00000000)
      else $fatal(1, "Reset failed: pc_out = %h", pc_out);

    rst = 0;

    // Load a new PC
    enable  = 1;
    next_pc = 32'h00000004;
    @(posedge clk);
    #1;
    assert (pc_out == 32'h00000004)
      else $fatal(1, "PC update failed: pc_out = %h", pc_out);

    // Load another PC
    next_pc = 32'h12345678;
    @(posedge clk);
    #1;
    assert (pc_out == 32'h12345678)
      else $fatal(1, "Second PC update failed: pc_out = %h", pc_out);

    // Disable: PC should hold
    enable  = 0;
    next_pc = 32'hDEADBEEF;
    @(posedge clk);
    #1;
    assert (pc_out == 32'h12345678)
      else $fatal(1, "PC hold failed: pc_out = %h", pc_out);

    // Reset must override enable
    rst     = 1;
    enable  = 1;
    next_pc = 32'hCAFEBABE;
    @(posedge clk);
    #1;
    assert (pc_out == 32'h00000000)
      else $fatal(1, "Reset priority failed: pc_out = %h", pc_out);

    $display("program_counter_tb: PASS");
    $finish;
  end

endmodule
