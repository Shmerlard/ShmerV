timeunit 1ns / 1ps;

// Simulation model only; the board uses Gowin's IOBUF primitive.
module IOBUF (
    input  wire I,
    input  wire OEN,
    output wire O,
    inout  wire IO
);
  assign IO = OEN ? 1'bz : I;
  assign O  = IO;
endmodule

module board_clock_check #(
    parameter int unsigned Divide = 4
) (
    output logic done = 1'b0
);
  logic clk = 1'b0;
  wire [7:0] port_a_io;
  wire [7:0] port_b_io;
  wire [7:0] port_c_io;

  soc_top #(
      .ENABLE_HDMI (1'b0),
      .CLOCK_DIVIDE(Divide)
  ) dut (
      .clk(clk),
      .reset_button_n_i(1'b0),
      .port_a_io(port_a_io),
      .port_b_io(port_b_io),
      .port_c_io(port_c_io),
      .tmds_clk_p(),
      .tmds_clk_n(),
      .tmds_d_p(),
      .tmds_d_n()
  );

  always #5ns clk = ~clk;

  initial begin
    assert (dut.soc.peripheral_manager.uart.tx.tx_bit_timer.BitCycles[
        uart_types::UART_SPEED_9600] ==
        (27_000_000 / Divide + 4800) / 9600);
    assert (dut.soc.peripheral_manager.uart.rx.rx_bit_timer.BitCycles[
        uart_types::UART_SPEED_9600] ==
        (27_000_000 / Divide + 4800) / 9600);
    for (int cycle_index = 1; cycle_index <= 256; cycle_index++) begin
      @(posedge clk);
      #1ns;
      assert (dut.cpu_clk == ((cycle_index - 1) % Divide >= Divide - Divide / 2));
    end
    done = 1'b1;
  end
endmodule

module soc_top_tb;
  logic [4:0] done;
  board_clock_check #(.Divide(2)) divide_2 (.done(done[0]));
  board_clock_check divide_4 (.done(done[1]));
  board_clock_check #(.Divide(16)) divide_16 (.done(done[2]));
  board_clock_check #(.Divide(32)) divide_32 (.done(done[3]));
  board_clock_check #(.Divide(64)) divide_64 (.done(done[4]));
  initial begin
    wait (&done);
    $display("Board clock division and UART frequency propagation tests passed");
    $finish;
  end
endmodule
