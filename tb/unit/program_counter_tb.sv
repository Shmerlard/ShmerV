timeunit 1ns / 1ps;

module program_counter_tb;

  logic        clk;
  logic        rst;
  logic        enable_i;
  logic [31:0] next_pc_i;
  logic [31:0] pc_o;

  program_counter dut (
      .clk      (clk),
      .rst      (rst),
      .enable_i (enable_i),
      .next_pc_i(next_pc_i),
      .pc_o     (pc_o)
  );

  always #5 clk = ~clk;

  initial begin
    clk       = 0;
    rst       = 0;
    enable_i  = 0;
    next_pc_i = 32'h00000000;

    // Reset
    rst       = 1;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000000)
    else $fatal(1, "Reset failed: pc_o = %h", pc_o);

    rst = 0;

    // Load a new PC
    enable_i = 1;
    next_pc_i = 32'h00000004;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000004)
    else $fatal(1, "PC update failed: pc_o = %h", pc_o);

    // Load another PC
    next_pc_i = 32'h12345678;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h12345678)
    else $fatal(1, "Second PC update failed: pc_o = %h", pc_o);

    // Disable: PC should hold
    enable_i  = 0;
    next_pc_i = 32'hDEADBEEF;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h12345678)
    else $fatal(1, "PC hold failed: pc_o = %h", pc_o);

    // Reset must override enable_i
    rst       = 1;
    enable_i  = 1;
    next_pc_i = 32'hCAFEBABE;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000000)
    else $fatal(1, "Reset priority failed: pc_o = %h", pc_o);

    $display("program_counter_tb: PASS");
    $finish;
  end

endmodule
