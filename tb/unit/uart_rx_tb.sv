timeunit 1ns / 1ps;
import uart_types::*;

module uart_rx_check #(
    parameter int unsigned ClockHz = 843_750
) (output logic done = 0);
  logic clk = 0, rst = 1, rx_line = 1, enable_i = 0, clear_ifg_i = 0;
  uart_speed_t uart_speed_i = UART_SPEED_9600;
  logic [7:0] rx_data_o;
  logic rx_ifg_o;
  localparam int Periods [0:3] = ClockHz == 843_750
      ? '{88, 44, 15, 7} : '{2813, 1406, 469, 234};
  localparam logic [7:0] Payloads [0:3] = '{8'h00, 8'hFF, 8'h53, 8'hAC};

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
    @(posedge clk); #1ns;
  endtask
  task automatic send_frame(input logic [7:0] payload, input int period);
    rx_line = 0; repeat (period) #10ns;
    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      rx_line = payload[bit_index]; repeat (period) #10ns;
    end
    rx_line = 1; repeat (period) #10ns;
  endtask
  task automatic check_received(input logic [7:0] payload);
    assert (rx_ifg_o && rx_data_o == payload)
    else $fatal(1, "RX expected %h got %h, pending %b, Hz %0d", payload, rx_data_o, rx_ifg_o, ClockHz);
  endtask
  task automatic acknowledge;
    clear_ifg_i = 1; tick(); clear_ifg_i = 0;
    assert (!rx_ifg_o);
  endtask
  task automatic await_received(input logic [7:0] payload);
    for (int cycle = 0; cycle < 8 && !rx_ifg_o; cycle++) tick();
    check_received(payload);
  endtask

  initial begin
    tick(); assert (!rx_ifg_o && rx_data_o == 0); rst = 0;
    for (int speed = 0; speed < 4; speed++) begin
      enable_i = 0; tick();
      uart_speed_i = uart_speed_t'(speed); enable_i = 1;
      repeat (4) tick();
      foreach (Payloads[i]) begin
        // Change the external line away from clock edges.
        @(negedge clk); #2ns;
        send_frame(Payloads[i], Periods[speed]);
        await_received(Payloads[i]); acknowledge();
      end

      send_frame(8'h69, Periods[speed]); await_received(8'h69);
      enable_i = 0; tick(); check_received(8'h69);
      acknowledge();
      rx_line = 0; repeat (2 * Periods[speed]) tick();
      assert (!rx_ifg_o && rx_data_o == 8'h69);
      rx_line = 1; repeat (4) tick(); enable_i = 1; repeat (4) tick();

      // Disabling mid-frame must discard the partial frame.
      rx_line = 0; repeat (2 * Periods[speed]) tick();
      enable_i = 0; tick(); rx_line = 1;
      repeat (4) tick(); enable_i = 1;
      repeat (11 * Periods[speed]) tick();
      assert (!rx_ifg_o && rx_data_o == 8'h69);

      // A read/acknowledgement concurrent with completion must retain the new flag.
      fork
        send_frame(8'hA6, Periods[speed]);
        begin
          wait (dut.rx_state == RX_FINISH);
          @(negedge clk); clear_ifg_i = 1;
          tick(); clear_ifg_i = 0;
          check_received(8'hA6);
        end
      join
      check_received(8'hA6); acknowledge();

      // Consecutive frames, with acknowledgement while their stop bits finish.
      fork
        begin
          send_frame(8'h35, Periods[speed]);
          send_frame(8'hCA, Periods[speed]);
        end
        begin
          wait (rx_ifg_o); #1ns; check_received(8'h35); acknowledge();
          wait (rx_ifg_o); #1ns; check_received(8'hCA);
        end
      join
      rst = 1; tick(); assert (!rx_ifg_o && rx_data_o == 0); rst = 0;
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
    wait (&done); $display("UART RX tests passed"); $finish;
  end
  initial begin
    #10ms; $fatal(1, "UART RX test timeout");
  end
endmodule
