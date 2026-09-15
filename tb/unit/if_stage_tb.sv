timeunit 1ns / 1ps;

module if_stage_tb;

  logic        clk;
  logic        rst;
  logic        pc_write_enable_i;
  logic [31:0] imem_read_data_i;
  logic        pc_redirect_enable_i;
  logic [31:0] pc_redirect_address_i;

  logic [31:0] imem_read_address_o;
  logic [31:0] instruction_o;
  logic [31:0] pc_o;

  if_stage dut (
      .clk                  (clk),
      .rst                  (rst),
      .pc_write_enable_i    (pc_write_enable_i),
      .imem_read_data_i     (imem_read_data_i),
      .imem_read_address_o  (imem_read_address_o),
      .instruction_o        (instruction_o),
      .pc_o                 (pc_o),
      .pc_redirect_enable_i (pc_redirect_enable_i),
      .pc_redirect_address_i(pc_redirect_address_i)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("build/tests/if_stage/waveform.fst");
    $dumpvars(0, if_stage_tb);

    clk                   = 1'b0;
    rst                   = 1'b1;
    pc_write_enable_i     = 1'b1;
    imem_read_data_i      = 32'h12345678;
    pc_redirect_enable_i  = 1'b0;
    pc_redirect_address_i = '0;

    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000000);
    assert (imem_read_address_o == pc_o);
    assert (instruction_o == imem_read_data_i);

    rst = 1'b0;

    // Sequential fetch
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000004);

    // Redirect fetch
    pc_redirect_enable_i  = 1'b1;
    pc_redirect_address_i = 32'h00000100;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000100);
    assert (imem_read_address_o == 32'h00000100);

    // Disabled PC holds even when redirect is requested
    pc_write_enable_i     = 1'b0;
    pc_redirect_address_i = 32'h00000200;
    @(posedge clk);
    #1;
    assert (pc_o == 32'h00000100);

    $display("if_stage_tb: PASS");
    $finish;
  end

endmodule
