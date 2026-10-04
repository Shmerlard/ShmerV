timeunit 1ns / 1ps;

module memory_tb;

  logic clk;
  logic [31:0] port_a_read_address_i;
  logic port_a_read_enable_i;
  logic [31:0] port_b_address_i;
  logic port_b_write_enable_i;
  logic [3:0] port_b_write_byte_enable_i;
  logic port_b_enable_i;
  logic [31:0] port_b_write_data_i;
  logic [31:0] port_a_read_data_o;
  logic [31:0] port_b_read_data_o;

  memory #(
      .MEM_WORDS(1024)
  ) dut (
      .clk                       (clk),
      .port_a_read_address_i     (port_a_read_address_i),
      .port_a_read_enable_i      (port_a_read_enable_i),
      .port_a_read_data_o        (port_a_read_data_o),
      .port_b_address_i          (port_b_address_i),
      .port_b_write_enable_i     (port_b_write_enable_i),
      .port_b_write_byte_enable_i(port_b_write_byte_enable_i),
      .port_b_enable_i           (port_b_enable_i),
      .port_b_write_data_i       (port_b_write_data_i),
      .port_b_read_data_o        (port_b_read_data_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic set_memory_word(input int index, input logic [31:0] value);
    dut.memory_lane0[index] = value[7:0];
    dut.memory_lane1[index] = value[15:8];
    dut.memory_lane2[index] = value[23:16];
    dut.memory_lane3[index] = value[31:24];
  endtask

  function automatic logic [31:0] get_memory_word(input int index);
    return {
      dut.memory_lane3[index],
      dut.memory_lane2[index],
      dut.memory_lane1[index],
      dut.memory_lane0[index]
    };
  endfunction

  initial begin
    $dumpfile("build/tests/memory/waveform.fst");
    $dumpvars(0, memory_tb);

    port_a_read_address_i = '0;
    port_a_read_enable_i = 1'b1;
    port_b_address_i = '0;
    port_b_write_enable_i = 1'b0;
    port_b_write_byte_enable_i = 4'b0000;
    port_b_enable_i = 1'b0;
    port_b_write_data_i = '0;

    // Preload memory
    set_memory_word(0, 32'h1234_5678);
    set_memory_word(1, 32'hDEAD_BEEF);
    set_memory_word(7, 32'hCAFE_BABE);

    // Read word 0
    port_a_read_address_i = 32'h0000_0000;
    @(posedge clk);
    #1;
    assert (port_a_read_data_o == 32'h1234_5678)
    else $fatal(1, "Expected 12345678, got %h", port_a_read_data_o);

    // Change address -- output should not change until next clock
    port_a_read_address_i = 32'h0000_0004;
    #1;
    assert (port_a_read_data_o == 32'h1234_5678)
    else $fatal(1, "Memory read changed asynchronously");

    // Disabled Port A reads hold the current instruction value.
    port_a_read_enable_i = 1'b0;
    @(posedge clk);
    #1;
    assert (port_a_read_data_o == 32'h1234_5678)
    else $fatal(1, "Disabled Port A read changed the output");

    port_a_read_enable_i = 1'b1;
    @(posedge clk);
    #1;
    assert (port_a_read_data_o == 32'hDEAD_BEEF)
    else $fatal(1, "Expected DEADBEEF, got %h", port_a_read_data_o);

    // Check address-to-word indexing: address 0x1C -> mem[7]
    port_a_read_address_i = 32'h0000_001C;
    @(posedge clk);
    #1;
    assert (port_a_read_data_o == 32'hCAFE_BABE)
    else $fatal(1, "Expected CAFEBABE, got %h", port_a_read_data_o);

    // Write word 2 using byte address 0x08.
    port_b_enable_i = 1'b1;
    port_b_address_i = 32'h0000_0008;
    port_b_write_data_i = 32'hAABB_CCDD;
    port_b_write_enable_i = 1'b1;
    port_b_write_byte_enable_i = 4'b1111;
    @(posedge clk);
    #1;
    port_b_write_enable_i = 1'b0;

    // Read the written word through Port B.
    port_b_address_i = 32'h0000_0008;
    port_b_enable_i = 1'b1;
    @(posedge clk);
    #1;
    assert (port_b_read_data_o == 32'hAABB_CCDD)
    else $fatal(1, "Expected AABBCCDD from Port B, got %h", port_b_read_data_o);

    // A byte-enable mask updates selected lanes and preserves the others.
    port_b_write_data_i = 32'h1122_3344;
    port_b_write_enable_i = 1'b1;
    port_b_write_byte_enable_i = 4'b0101;
    @(posedge clk);
    #1;
    assert (port_b_read_data_o == 32'hAA22_CC44)
    else $fatal(1, "Expected write-first result AA22CC44, got %h", port_b_read_data_o);
    port_b_write_enable_i = 1'b0;

    @(posedge clk);
    #1;
    assert (port_b_read_data_o == 32'hAA22_CC44)
    else $fatal(1, "Expected AA22CC44 after masked write, got %h", port_b_read_data_o);

    // Disabled Port B reads hold the previous output value.
    port_b_enable_i  = 1'b0;
    port_b_address_i = 32'h0000_0004;
    @(posedge clk);
    #1;
    assert (port_b_read_data_o == 32'hAA22_CC44)
    else $fatal(1, "Disabled Port B read changed the output");

    // The shared enable must suppress writes even when write is selected.
    port_b_write_enable_i = 1'b1;
    port_b_write_byte_enable_i = 4'b1111;
    port_b_write_data_i = 32'h0;
    @(posedge clk);
    #1;
    assert (get_memory_word(1) == 32'hDEAD_BEEF)
    else $fatal(1, "Disabled Port B write changed memory");
    assert (port_b_read_data_o == 32'hAA22_CC44)
    else $fatal(1, "Disabled Port B write changed output");

    $display("memory tests passed");
    $finish;
  end

endmodule
