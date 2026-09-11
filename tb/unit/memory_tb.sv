timeunit 1ns / 1ps;

module memory_tb;

  logic clk;
  logic [31:0] instruction_read_address_i;
  logic [31:0] data_read_address_i;
  logic [31:0] data_write_address_i;
  logic data_write_enable_i;
  logic [31:0] data_write_data_i;
  logic [31:0] instruction_read_data_o;
  logic [31:0] data_read_data_o;

  memory #(
      .MEM_WORDS(1024)
  ) dut (
      .clk                       (clk),
      .instruction_read_address_i(instruction_read_address_i),
      .data_read_address_i       (data_read_address_i),
      .data_write_address_i      (data_write_address_i),
      .data_write_enable_i       (data_write_enable_i),
      .data_write_data_i         (data_write_data_i),
      .instruction_read_data_o   (instruction_read_data_o),
      .data_read_data_o          (data_read_data_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    instruction_read_address_i = '0;
    data_read_address_i = '0;
    data_write_address_i = '0;
    data_write_enable_i = 1'b0;
    data_write_data_i = '0;

    // Preload memory
    dut.memory_words[0] = 32'h1234_5678;
    dut.memory_words[1] = 32'hDEAD_BEEF;
    dut.memory_words[7] = 32'hCAFE_BABE;

    // Read word 0
    instruction_read_address_i = 32'h0000_0000;
    @(posedge clk);
    #1;
    assert (instruction_read_data_o == 32'h1234_5678)
    else $fatal(1, "Expected 12345678, got %h", instruction_read_data_o);

    // Change address -- output should not change until next clock
    instruction_read_address_i = 32'h0000_0004;
    #1;
    assert (instruction_read_data_o == 32'h1234_5678)
    else $fatal(1, "Memory read changed asynchronously");

    @(posedge clk);
    #1;
    assert (instruction_read_data_o == 32'hDEAD_BEEF)
    else $fatal(1, "Expected DEADBEEF, got %h", instruction_read_data_o);

    // Check address-to-word indexing: address 0x1C -> mem[7]
    instruction_read_address_i = 32'h0000_001C;
    @(posedge clk);
    #1;
    assert (instruction_read_data_o == 32'hCAFE_BABE)
    else $fatal(1, "Expected CAFEBABE, got %h", instruction_read_data_o);

    // Write word 2 using byte address 0x08.
    data_write_address_i = 32'h0000_0008;
    data_write_data_i = 32'hAABB_CCDD;
    data_write_enable_i = 1'b1;
    @(posedge clk);
    #1;
    data_write_enable_i = 1'b0;

    // Read the written word through Port B.
    data_read_address_i = 32'h0000_0008;
    @(posedge clk);
    #1;
    assert (data_read_data_o == 32'hAABB_CCDD)
    else $fatal(1, "Expected AABBCCDD from Port B, got %h", data_read_data_o);

    $display("memory tests passed");
    $finish;
  end

endmodule
