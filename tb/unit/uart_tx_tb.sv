timeunit 1ns / 1ps;
import uart_types::*;

module uart_tx_check #(
    parameter int unsigned ClockHz = 843_750
) (output logic done = 0);
  logic clk = 0, rst = 1, enable_i = 0, start_i = 0;
  uart_speed_t uart_speed_i = UART_SPEED_9600;
  logic [7:0] data_i = 0;
  logic tx_o, busy_o, idle_o, finish_o;
  localparam int Periods [0:3] = ClockHz == 843_750
      ? '{88, 44, 15, 7} : '{2813, 1406, 469, 234};
  localparam logic [7:0] Payloads [0:3] = '{8'h00, 8'hFF, 8'h53, 8'hAC};

  always #5ns clk = ~clk;
  uart_tx #(.CLOCK_HZ(ClockHz)) dut (.*);
  task automatic tick;
    @(posedge clk); #1ns;
  endtask
  task automatic check_idle;
    assert (tx_o && idle_o && !busy_o && !finish_o)
    else $fatal(1, "TX did not idle at %0d Hz", ClockHz);
  endtask
  task automatic send_and_check(input logic [7:0] payload, input int period);
    logic [9:0] frame;
    frame = {1'b1, payload, 1'b0};
    data_i = payload; start_i = 1; tick(); start_i = 0;
    assert (tx_o && busy_o && !idle_o);
    tick();
    // A frame must retain its captured data despite input changes.
    data_i = ~payload;
    for (int bit_index = 0; bit_index < 10; bit_index++) begin
      for (int cycle = 0; cycle < period; cycle++) begin
        assert (tx_o == frame[bit_index] && busy_o && !finish_o)
        else $fatal(1, "TX frame %h bit %0d cycle %0d, Hz %0d", payload, bit_index, cycle, ClockHz);
        // A start pulse during a frame must not queue another transmission.
        start_i = (bit_index == 2 && cycle == 0);
        tick();
      end
    end
    start_i = 0;
    tick(); assert (finish_o && !busy_o && tx_o);
    tick(); check_idle();
    repeat (3) begin tick(); check_idle(); end
  endtask

  initial begin
    tick(); check_idle(); rst = 0;
    start_i = 1; repeat (3) begin tick(); check_idle(); end
    start_i = 0;
    for (int speed = 0; speed < 4; speed++) begin
      enable_i = 0; tick();
      uart_speed_i = uart_speed_t'(speed); enable_i = 1;
      foreach (Payloads[i]) send_and_check(Payloads[i], Periods[speed]);
      start_i = 1; tick(); start_i = 0; tick();
      repeat (Periods[speed]) tick();
      enable_i = 0; tick(); check_idle();
      enable_i = 1; repeat (3) begin tick(); check_idle(); end
      start_i = 1; tick(); start_i = 0; tick();
      rst = 1; tick(); check_idle(); rst = 0;
      tick(); check_idle();
    end
    done = 1;
  end
endmodule

module uart_tx_tb;
  logic [1:0] done;
  uart_tx_check board_clock (.done(done[0]));
  uart_tx_check #(.ClockHz(27_000_000)) fast_clock (.done(done[1]));
  initial begin
    $dumpfile("build/tests/uart_tx/waveform.fst");
    $dumpvars(0, uart_tx_tb);
    wait (&done); $display("UART TX tests passed"); $finish;
  end
  initial begin
    #10ms; $fatal(1, "UART TX test timeout");
  end
endmodule
