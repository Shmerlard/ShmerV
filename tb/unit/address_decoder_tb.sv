timeunit 1ns / 1ps;

module address_decoder_tb;
  localparam logic [31:0] RamBaseAddress = 32'h8000_0000;
  localparam logic [31:0] RamSizeBytes = 32'h0000_8000;
  localparam logic [31:0] PeripheralBaseAddress = 32'h1000_0000;
  localparam logic [31:0] PeripheralSizeBytes = 32'h0001_0000;

  logic clk = 1'b0;
  logic rst;
  logic [31:0] address_i;
  logic read_enable_i;
  logic write_enable_i;
  logic ram_read_enable_o;
  logic ram_write_enable_o;
  logic [31:0] ram_read_data_i;
  logic peripheral_read_enable_o;
  logic peripheral_write_enable_o;
  logic [31:0] peripheral_read_data_i;
  logic [31:0] read_data_o;
  logic address_overlap_o;

  logic overlap_ram_read_enable;
  logic overlap_ram_write_enable;
  logic overlap_peripheral_read_enable;
  logic overlap_peripheral_write_enable;
  logic [31:0] overlap_read_data;
  logic overlap_detected;

  address_decoder #(
      .RAM_BASE_ADDRESS       (RamBaseAddress),
      .RAM_SIZE_BYTES         (RamSizeBytes),
      .PERIPHERAL_BASE_ADDRESS(PeripheralBaseAddress),
      .PERIPHERAL_SIZE_BYTES  (PeripheralSizeBytes)
  ) dut (
      .*
  );

  address_decoder #(
      .RAM_BASE_ADDRESS       (32'h8000_0000),
      .RAM_SIZE_BYTES         (32'h0000_8000),
      .PERIPHERAL_BASE_ADDRESS(32'h8000_4000),
      .PERIPHERAL_SIZE_BYTES  (32'h0001_0000)
  ) overlap_dut (
      .clk                      (clk),
      .rst                      (rst),
      .address_i                (address_i),
      .read_enable_i            (read_enable_i),
      .write_enable_i           (write_enable_i),
      .ram_read_enable_o        (overlap_ram_read_enable),
      .ram_write_enable_o       (overlap_ram_write_enable),
      .ram_read_data_i          (ram_read_data_i),
      .peripheral_read_enable_o (overlap_peripheral_read_enable),
      .peripheral_write_enable_o(overlap_peripheral_write_enable),
      .peripheral_read_data_i   (peripheral_read_data_i),
      .read_data_o              (overlap_read_data),
      .address_overlap_o        (overlap_detected)
  );

  always #5ns clk = ~clk;

  initial begin
    $dumpfile("build/tests/address_decoder/waveform.fst");
    $dumpvars(0, address_decoder_tb);

    rst = 1'b1;
    address_i = '0;
    read_enable_i = 1'b0;
    write_enable_i = 1'b0;
    ram_read_data_i = 32'hAABB_CCDD;
    peripheral_read_data_i = 32'h1234_5678;

    @(posedge clk);
    #1ns;
    rst = 1'b0;
    assert (read_data_o == 32'b0);

    // A RAM request enables only RAM.
    address_i = RamBaseAddress;
    read_enable_i = 1'b1;
    #1ns;
    assert (ram_read_enable_o);
    assert (!peripheral_read_enable_o);

    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == ram_read_data_i);

    // A peripheral request enables only the peripheral manager.
    address_i = PeripheralBaseAddress;
    write_enable_i = 1'b1;
    #1ns;
    assert (peripheral_write_enable_o);
    assert (!ram_write_enable_o);

    write_enable_i = 1'b0;
    read_enable_i  = 1'b1;
    #1ns;
    assert (peripheral_read_enable_o);
    assert (!ram_read_enable_o);

    @(posedge clk);
    #1ns;
    read_enable_i = 1'b0;
    assert (read_data_o == peripheral_read_data_i);

    // The saved selection, not the new live address, chooses the response.
    address_i = RamBaseAddress;
    assert (read_data_o == peripheral_read_data_i);

    // Overlapping regions enable neither destination and report the conflict.
    address_i = 32'h8000_4000;
    read_enable_i = 1'b1;
    write_enable_i = 1'b1;
    #1ns;
    assert (overlap_detected);
    assert (!overlap_ram_read_enable && !overlap_ram_write_enable);
    assert (!overlap_peripheral_read_enable && !overlap_peripheral_write_enable);

    @(posedge clk);
    #1ns;
    read_enable_i  = 1'b0;
    write_enable_i = 1'b0;
    assert (overlap_read_data == 32'b0);

    // Unmapped requests enable nothing and unmapped reads return zero.
    address_i = 32'h2000_0000;
    read_enable_i = 1'b1;
    write_enable_i = 1'b1;
    #1ns;
    assert (!ram_read_enable_o && !ram_write_enable_o);
    assert (!peripheral_read_enable_o && !peripheral_write_enable_o);

    @(posedge clk);
    #1ns;
    read_enable_i  = 1'b0;
    write_enable_i = 1'b0;
    assert (read_data_o == 32'b0);

    $display("address decoder tests passed");
    $finish;
  end
endmodule
