timeunit 1ns / 1ps;
import uart_types::*;

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
  uart_registers_address_t register_address_i;
  logic mmio_write_enable_i;
  logic mmio_read_enable_i;
  logic [7:0] mmio_read_data_o;
  logic tx_o;

  uart_module #(
      .CLOCK_HZ (ClockHz),
      .BAUD_RATE(BaudRate)
  ) dut (
      .*
  );

  always #5ns clk = ~clk;

  task automatic write_register(input uart_registers_address_t address, input logic [7:0] data);
    register_address_i  = address;
    mmio_write_data_i   = data;
    mmio_write_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    mmio_write_enable_i = 1'b0;
  endtask

  task automatic check_read(input uart_registers_address_t address, input logic [7:0] expected);
    register_address_i = address;
    mmio_read_enable_i = 1'b1;
    @(posedge clk);
    #1ns;
    mmio_read_enable_i = 1'b0;
    assert (mmio_read_data_o == expected)
    else $fatal(1, "UART register %0d: expected %h, got %h", address, expected, mmio_read_data_o);
  endtask

  initial begin
    logic [9:0] expected_frame;

    rst = 1'b1;
    mmio_write_data_i = '0;
    register_address_i = UART_TX_ADDRESS;
    mmio_write_enable_i = 1'b0;
    mmio_read_enable_i = 1'b0;

    @(posedge clk);
    #1ns;
    rst = 1'b0;
    assert (tx_o == 1'b1);
    assert (mmio_read_data_o == 8'h00);
    check_read(UART_TX_ADDRESS, 8'h00);
    check_read(UART_CTRL_REG_ADDRESS, 8'h00);

    // Software cannot set BUSY or reserved bits while idle.
    write_register(UART_CTRL_REG_ADDRESS, 8'hFE);
    check_read(UART_CTRL_REG_ADDRESS, 8'h00);

    expected_frame = {1'b1, 8'h53, 1'b0};
    write_register(UART_TX_ADDRESS, 8'h53);
    check_read(UART_TX_ADDRESS, 8'h53);
    register_address_i = UART_CTRL_REG_ADDRESS;
    repeat (2) begin
      @(posedge clk);
      #1ns;
      assert (mmio_read_data_o == 8'h53);
    end
    write_register(UART_CTRL_REG_ADDRESS, 8'h01);
    // A pending START protects DATA even before BUSY asserts.
    write_register(UART_TX_ADDRESS, 8'hAC);
    register_address_i = UART_CTRL_REG_ADDRESS;
    // Poll throughout transmission, including the FINISH cycle.
    mmio_read_enable_i = 1'b1;

    @(negedge tx_o);
    // Check every clock of every bit, including the one-cycle counter case.
    for (int bit_index = 0; bit_index < 10; bit_index++) begin
      for (int cycle_index = 0; cycle_index < CyclesForBit; cycle_index++) begin
        #1ns;
        assert (tx_o == expected_frame[bit_index]);
        // Attempt to cancel START and replace DATA during the frame.
        mmio_write_enable_i = (cycle_index == 0 && bit_index < 2);
        register_address_i  = bit_index == 1 ? UART_TX_ADDRESS : UART_CTRL_REG_ADDRESS;
        mmio_write_data_i   = bit_index == 1 ? 8'hAC : 8'h00;
        @(posedge clk);
      end
    end

    #1ns;
    mmio_write_enable_i = 1'b0;
    register_address_i  = UART_CTRL_REG_ADDRESS;
    assert (mmio_read_data_o == 8'h03);
    @(posedge clk);
    #1ns;
    assert (mmio_read_data_o == 8'h03);
    @(posedge clk);
    #1ns;
    // FINISH is idle on TX, but START clears at this edge.
    assert (mmio_read_data_o == 8'h01)
    else $fatal(1, "Read during FINISH returned stale busy status");
    check_read(UART_CTRL_REG_ADDRESS, 8'h00);
    check_read(UART_TX_ADDRESS, 8'h53);

    // START self-clears after one frame, so the transmitter remains idle.
    repeat (8) begin
      @(posedge clk);
      #1ns;
      assert (tx_o == 1'b1);
    end

    // START cannot be canceled while pending or while transmitting.
    write_register(UART_CTRL_REG_ADDRESS, 8'h01);
    write_register(UART_CTRL_REG_ADDRESS, 8'h00);
    repeat (2) @(posedge clk);
    #1ns;
    write_register(UART_CTRL_REG_ADDRESS, 8'h00);
    check_read(UART_CTRL_REG_ADDRESS, 8'h03);

    // Reset interrupts transmission and clears the registered read response.
    rst = 1'b1;
    @(posedge clk);
    #1ns;
    assert (tx_o == 1'b1 && mmio_read_data_o == 8'h00);
    rst = 1'b0;
    check_read(UART_CTRL_REG_ADDRESS, 8'h00);
    check_read(UART_TX_ADDRESS, 8'h00);

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
