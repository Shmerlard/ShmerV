timeunit 1ns / 1ps;

module uart_module_tb;
  localparam int unsigned CyclesForBit = 4;

  logic clk = 1'b0;
  logic rst;
  logic [7:0] mmio_write_data_i;
  logic register_address_i;
  logic mmio_write_enable_i;
  logic tx_o;

  uart_module #(.CYCLES_FOR_BIT(CyclesForBit)) dut (.*);

  always #5ns clk = ~clk;

  task automatic write_register(input logic address, input logic [7:0] data);
    register_address_i  = address;
    mmio_write_data_i   = data;
    mmio_write_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    mmio_write_enable_i = 1'b0;
  endtask

  initial begin
    logic [9:0] expected_frame;

    $dumpfile("build/tests/uart_module/waveform.fst");
    $dumpvars(0, uart_module_tb);

    rst = 1'b1;
    mmio_write_data_i = '0;
    register_address_i = 1'b0;
    mmio_write_enable_i = 1'b0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;
    assert (tx_o == 1'b1);

    expected_frame = {1'b1, 8'h53, 1'b0};
    write_register(1'b0, 8'h53);
    write_register(1'b1, 8'h01);

    @(negedge tx_o);
    repeat (CyclesForBit / 2) @(posedge clk);
    #1ns;
    assert (tx_o == expected_frame[0]);

    for (int bit_index = 1; bit_index < 10; bit_index++) begin
      repeat (CyclesForBit) @(posedge clk);
      #1ns;
      assert (tx_o == expected_frame[bit_index]);
    end

    // START self-clears after one frame, so the transmitter remains idle.
    repeat (8) begin
      @(posedge clk);
      #1ns;
      assert (tx_o == 1'b1);
    end

    $display("UART transmitter tests passed");
    $finish;
  end
endmodule
