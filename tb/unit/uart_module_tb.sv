timeunit 1ns / 1ps;

module uart_frame_check #(
    parameter int unsigned ClockHz = 36_000,
    parameter int unsigned BaudRate = 10_000,
    parameter int unsigned CyclesForBit = 4
) (
    output logic done = 1'b0
);

  logic clk = 1'b0;
  logic rst;
  logic [7:0] mmio_write_data_i;
  logic register_address_i;
  logic mmio_write_enable_i;
  logic tx_o;

  uart_module #(
      .CLOCK_HZ (ClockHz),
      .BAUD_RATE(BaudRate)
  ) dut (
      .*
  );

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
    // Check every clock of every bit, including the one-cycle counter case.
    for (int bit_index = 0; bit_index < 10; bit_index++) begin
      for (int cycle_index = 0; cycle_index < CyclesForBit; cycle_index++) begin
        #1ns;
        assert (tx_o == expected_frame[bit_index]);
        @(posedge clk);
      end
    end

    // START self-clears after one frame, so the transmitter remains idle.
    repeat (8) begin
      @(posedge clk);
      #1ns;
      assert (tx_o == 1'b1);
    end

    done = 1'b1;
  end
endmodule

module uart_module_tb;
  logic [3:0] done;
  // Rounding up, rounding down, board defaults, and one cycle per bit.
  uart_frame_check rounded_up (.done(done[0]));
  uart_frame_check #(
      .ClockHz(34_000),
      .CyclesForBit(3)
  ) rounded_down (
      .done(done[1])
  );
  uart_frame_check #(
      .ClockHz(843_750),
      .BaudRate(9600),
      .CyclesForBit(88)
  ) board_clock (
      .done(done[2])
  );
  uart_frame_check #(
      .ClockHz(10_000),
      .CyclesForBit(1)
  ) single_cycle (
      .done(done[3])
  );

  initial begin
    $dumpfile("build/tests/uart_module/waveform.fst");
    $dumpvars(0, uart_module_tb);
    wait (&done);
    $display("UART transmitter tests passed");
    $finish;
  end

  initial begin
    #100us;
    $fatal(1, "UART test timeout");
  end
endmodule
