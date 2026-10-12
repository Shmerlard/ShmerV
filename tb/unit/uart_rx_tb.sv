timeunit 1ns / 1ps;
import uart_types::*;

module uart_rx_check #(
    parameter int unsigned ClockHz = 1_687_500
) (
    output logic done = 0
);
  logic clk = 0, rst = 1, rx_line = 1, enable_i = 0, clear_ifg_i = 0;
  uart_speed_t uart_speed_i = UART_SPEED_9600;
  logic [7:0] rx_data_o;
  logic rx_ifg_o;
  logic framing_error_o;
  logic overrun_o;
  localparam int Periods[0:3] = ClockHz == 1_687_500 ? '{176, 88, 29, 15} : '{2813, 1406, 469, 234};
  localparam logic [7:0] Payloads[0:3] = '{8'h00, 8'hFF, 8'h53, 8'hAC};

  logic rx_i, rx_sync_1;
  // Model the synchronized input supplied by GPIO in the SoC.
  always_ff @(posedge clk) begin
    if (rst) begin
      rx_sync_1 <= 0;
      rx_i <= 0;
    end else begin
      rx_sync_1 <= rx_line;
      rx_i <= rx_sync_1;
    end
  end

  always #5ns clk = ~clk;
  uart_rx #(.CLOCK_HZ(ClockHz)) dut (.*);
  task automatic tick;
    @(posedge clk);
    #1ns;
  endtask
  task automatic send_frame(input logic [7:0] payload, input int period,
                            input logic stop_bit = 1);
    rx_line = 0;
    repeat (period) #10ns;
    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      rx_line = payload[bit_index];
      repeat (period) #10ns;
    end
    rx_line = stop_bit;
    if (stop_bit) repeat (period) #10ns;
    else begin
      // Hold low through the stop sample, then release before a new start.
      wait (dut.rx_timer_tick && dut.rx_bit_index == 9);
      tick();
      rx_line = 1;
      repeat (8) tick();
    end
  endtask
  task automatic check_received(input logic [7:0] payload);
    assert (rx_ifg_o && rx_data_o == payload)
    else
      $fatal(1, "RX expected %h got %h, pending %b, Hz %0d", payload, rx_data_o, rx_ifg_o, ClockHz);
  endtask
  task automatic acknowledge;
    clear_ifg_i = 1;
    tick();
    clear_ifg_i = 0;
    assert (!rx_ifg_o && !overrun_o)
    else $fatal(1, "RX acknowledgement did not clear pending/overrun");
  endtask
  task automatic await_received(input logic [7:0] payload);
    for (int cycle = 0; cycle < 8 && !rx_ifg_o; cycle++) tick();
    check_received(payload);
  endtask

  initial begin
    tick();
    assert (!rx_ifg_o && rx_data_o == 0 && !framing_error_o && !overrun_o);
    rst = 0;
    for (int speed = 0; speed < 4; speed++) begin
      enable_i = 0;
      tick();
      uart_speed_i = uart_speed_t'(speed);
      enable_i = 1;
      repeat (4) tick();
      foreach (Payloads[i]) begin
        // Change the external line away from clock edges.
        @(negedge clk);
        #2ns;
        send_frame(Payloads[i], Periods[speed]);
        await_received(Payloads[i]);
        assert (!framing_error_o && !overrun_o)
        else $fatal(1,
            "Valid frame error: Hz=%0d speed=%0d cycles/bit=%0d payload=%h framing=%b overrun=%b sampled_frame=%b",
            ClockHz, speed, Periods[speed], Payloads[i], framing_error_o,
            overrun_o, dut.rx_in_reg);
        acknowledge();
      end

      send_frame(8'h42, Periods[speed], 0);
      await_received(8'h42);
      assert (framing_error_o && !overrun_o)
      else $fatal(1, "Low stop bit must set framing error only");
      acknowledge();
      assert (framing_error_o);  // Error still describes the stored byte.
      fork
        send_frame(8'h81, Periods[speed]);
        begin
          wait (dut.rx_state == RX_INITIALIZE);
          tick();
          assert (framing_error_o)
          else $fatal(1, "Starting a frame cleared the previous byte's error");
        end
      join
      await_received(8'h81);
      assert (!framing_error_o && !overrun_o);
      acknowledge();

      // Newest byte replaces unread data; overrun remains until acknowledgement.
      send_frame(8'h12, Periods[speed]);
      await_received(8'h12);
      send_frame(8'h34, Periods[speed], 0);
      check_received(8'h34);
      assert (overrun_o && framing_error_o)
      else $fatal(1, "Unread replacement did not report overrun/framing error");
      send_frame(8'h56, Periods[speed]);
      check_received(8'h56);
      assert (overrun_o && !framing_error_o)
      else $fatal(1, "Overrun must stick while framing follows the newest byte");
      acknowledge();

      // Reading the old pending byte exactly at completion is not an overrun.
      send_frame(8'h77, Periods[speed]);
      await_received(8'h77);
      fork
        send_frame(8'h88, Periods[speed]);
        begin
          wait (dut.rx_state == RX_FINISH);
          @(negedge clk);
          clear_ifg_i = 1;
          tick();
          clear_ifg_i = 0;
          check_received(8'h88);
          assert (!overrun_o && !framing_error_o)
          else $fatal(1, "Read at completion caused a false overrun");
        end
      join
      acknowledge();

      send_frame(8'h69, Periods[speed]);
      await_received(8'h69);
      enable_i = 0;
      tick();
      check_received(8'h69);
      acknowledge();
      rx_line = 0;
      repeat (2 * Periods[speed]) tick();
      assert (!rx_ifg_o && rx_data_o == 8'h69);
      rx_line = 1;
      repeat (4) tick();
      enable_i = 1;
      repeat (4) tick();

      // Disabling mid-frame must discard the partial frame.
      rx_line = 0;
      repeat (2 * Periods[speed]) tick();
      enable_i = 0;
      tick();
      rx_line = 1;
      repeat (4) tick();
      enable_i = 1;
      repeat (11 * Periods[speed]) tick();
      assert (!rx_ifg_o && rx_data_o == 8'h69);

      // A read/acknowledgement concurrent with completion must retain the new flag.
      fork
        send_frame(8'hA6, Periods[speed]);
        begin
          wait (dut.rx_state == RX_FINISH);
          @(negedge clk);
          clear_ifg_i = 1;
          tick();
          clear_ifg_i = 0;
          check_received(8'hA6);
        end
      join
      check_received(8'hA6);
      acknowledge();

      // Consecutive frames, with acknowledgement while their stop bits finish.
      fork
        begin
          send_frame(8'h35, Periods[speed]);
          send_frame(8'hCA, Periods[speed]);
        end
        begin
          wait (rx_ifg_o);
          #1ns;
          check_received(8'h35);
          acknowledge();
          wait (rx_ifg_o);
          #1ns;
          check_received(8'hCA);
        end
      join
      send_frame(8'h99, Periods[speed], 0);
      assert (framing_error_o && overrun_o);
      rst = 1;
      tick();
      assert (!rx_ifg_o && rx_data_o == 0 && !framing_error_o && !overrun_o);
      rst = 0;
    end
    done = 1;
  end
endmodule

module uart_rx_tb;
  logic [1:0] done;
  uart_rx_check board_clock (.done(done[0]));
  uart_rx_check #(.ClockHz(27_000_000)) fast_clock (.done(done[1]));
  initial begin
    $dumpfile("build/tests/uart_rx/waveform.fst");
    $dumpvars(0, uart_rx_tb);
    wait (&done);
    $display("UART RX tests passed");
    $finish;
  end
  initial begin
    #10ms;
    $fatal(1, "UART RX test timeout");
  end
endmodule
