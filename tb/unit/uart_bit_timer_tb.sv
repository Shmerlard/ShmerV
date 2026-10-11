timeunit 1ns / 1ps;
import uart_types::*;

module uart_timer_check #(
    parameter int unsigned ClockHz = 843_750
) (output logic done = 0);
  logic clk = 0, rst = 1, enable_i = 0;
  uart_speed_t uart_speed = UART_SPEED_9600;
  logic half_tick, full_tick;
  logic [3:0] half_index, full_index;
  localparam int Periods [0:3] = ClockHz == 843_750
      ? '{88, 44, 15, 7} : '{2813, 1406, 469, 234};

  always #5ns clk = ~clk;
  uart_bit_timer #(.CLOCK_HZ(ClockHz)) half_timer (
      .clk, .rst, .uart_speed, .enable_i,
      .bit_tick_o(half_tick), .bit_index_o(half_index)
  );
  uart_bit_timer #(.CLOCK_HZ(ClockHz), .INITIAL_HALF_BIT(0)) full_timer (
      .clk, .rst, .uart_speed, .enable_i,
      .bit_tick_o(full_tick), .bit_index_o(full_index)
  );
  task automatic tick;
    @(posedge clk); #1ns;
  endtask
  task automatic check_idle;
    assert (!half_tick && !full_tick && half_index == 0 && full_index == 0)
    else $fatal(1, "Timer did not reset at %0d Hz", ClockHz);
  endtask

  initial begin
    tick(); check_idle(); rst = 0;
    for (int speed = 0; speed < 4; speed++) begin
      enable_i = 0; tick(); check_idle();
      uart_speed = uart_speed_t'(speed);
      enable_i = 1; tick(); check_idle();
      for (int cycle = 1; cycle <= 3 * Periods[speed]; cycle++) begin
        tick();
        assert (full_tick == (cycle % Periods[speed] == 0))
        else $fatal(1, "Full-bit tick: clock %0d, speed %0d, Hz %0d", cycle, speed, ClockHz);
        assert (half_tick == (cycle >= Periods[speed] / 2 &&
            (cycle - Periods[speed] / 2) % Periods[speed] == 0))
        else $fatal(1, "Half-bit tick: clock %0d, speed %0d, Hz %0d", cycle, speed, ClockHz);
        assert (full_index == 4'(cycle / Periods[speed]));
        assert (half_index == 4'(cycle < Periods[speed] / 2 ? 0 :
            (cycle - Periods[speed] / 2) / Periods[speed]));
      end
      enable_i = 0; tick(); check_idle();
      enable_i = 1; tick();
      repeat (Periods[speed] / 2 - 1) tick();
      enable_i = 0; tick(); check_idle();
      enable_i = 1; tick();
      repeat (Periods[speed] / 2 - 1) begin
        tick(); assert (!half_tick && !full_tick);
      end
      tick(); assert (half_tick && !full_tick);
      rst = 1; tick(); check_idle(); rst = 0;
    end
    enable_i = 0;
    done = 1;
  end
endmodule

module uart_bit_timer_tb;
  logic [1:0] done;
  uart_timer_check board_clock (.done(done[0]));
  uart_timer_check #(.ClockHz(27_000_000)) fast_clock (.done(done[1]));
  initial begin
    $dumpfile("build/tests/uart_bit_timer/waveform.fst");
    $dumpvars(0, uart_bit_timer_tb);
    wait (&done); $display("UART bit timer tests passed"); $finish;
  end
  initial begin
    #2ms; $fatal(1, "UART timer test timeout");
  end
endmodule
