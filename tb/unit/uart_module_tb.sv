timeunit 1ns / 1ps;
import uart_types::*;

module uart_wrapper_check #(
    parameter int unsigned ClockHz = 843_750
) (output logic done = 0);
  logic clk = 0, rst = 1, rx_line = 1;
  logic [15:0] mmio_write_data_i = 0, mmio_read_data_o;
  uart_registers_address_t register_address_i = UART_CTRL_REG_ADDRESS;
  logic mmio_write_enable_i = 0, mmio_read_enable_i = 0;
  logic tx_o, rx_irq_o;
  uart_control_t config_value;
  localparam int Periods [0:3] = ClockHz == 843_750
      ? '{88, 44, 15, 7} : '{2813, 1406, 469, 234};

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
  uart_module #(.CLOCK_HZ(ClockHz)) dut (.*);
  task automatic tick;
    @(posedge clk); #1ns;
  endtask
  task automatic write_register(input uart_registers_address_t address, input logic [15:0] value);
    register_address_i = address; mmio_write_data_i = value;
    mmio_write_enable_i = 1; tick(); mmio_write_enable_i = 0;
  endtask
  task automatic check_read(input uart_registers_address_t address, input logic [15:0] expected);
    register_address_i = address; mmio_read_enable_i = 1;
    tick(); mmio_read_enable_i = 0;
    assert (mmio_read_data_o == expected)
    else $fatal(1, "UART register %0d expected %h got %h at %0d Hz",
        address, expected, mmio_read_data_o, ClockHz);
  endtask
  task automatic send_rx_frame(input logic [7:0] payload, input int period);
    rx_line = 0; repeat (period) #10ns;
    for (int bit_index = 0; bit_index < 8; bit_index++) begin
      rx_line = payload[bit_index]; repeat (period) #10ns;
    end
    rx_line = 1; repeat (period) #10ns;
  endtask
  task automatic check_tx_frame(input logic [7:0] payload, input int period);
    logic [9:0] frame;
    frame = {1'b1, payload, 1'b0};
    @(negedge tx_o); #1ns;
    for (int bit_index = 0; bit_index < 10; bit_index++) begin
      repeat (period) begin
        assert (tx_o == frame[bit_index])
        else $fatal(1, "Wrapper TX expected %h bit %0d at %0d Hz", payload, bit_index, ClockHz);
        tick();
      end
    end
  endtask

  initial begin
    uart_control_t request, attempted_config;
    assert ($bits(uart_control_t) == 16);
    tick(); assert (tx_o && !rx_irq_o && mmio_read_data_o == 0); rst = 0;
    check_read(UART_CTRL_REG_ADDRESS, 16'h0040);
    check_read(UART_TX_ADDRESS, 0);
    check_read(UART_RX_ADDRESS, 0);
    // Reserved, busy, pending and error bits cannot be set by software.
    write_register(UART_CTRL_REG_ADDRESS, 16'hF1D4);
    check_read(UART_CTRL_REG_ADDRESS, 16'h0040);
    write_register(UART_CTRL_REG_ADDRESS, 16'h0048);
    repeat (4) begin tick(); assert (tx_o); end
    check_read(UART_CTRL_REG_ADDRESS, 16'h0040);

    for (int speed = 0; speed < 4; speed++) begin
      write_register(UART_CTRL_REG_ADDRESS, 0);
      config_value = '0;
      config_value.uart_speed = uart_speed_t'(speed);
      config_value.lsb_first = 1;
      config_value.uart_enable = 1;
      config_value.rx_ie = 1;
      write_register(UART_CTRL_REG_ADDRESS, config_value);
      check_read(UART_CTRL_REG_ADDRESS, config_value);

      // Readback remains registered and stable without a read request.
      write_register(UART_TX_ADDRESS, 16'hAB53);
      check_read(UART_TX_ADDRESS, 16'h0053);
      register_address_i = UART_CTRL_REG_ADDRESS;
      repeat (3) begin tick(); assert (mmio_read_data_o == 16'h0053); end

      request = config_value; request.start_tx = 1;
      write_register(UART_CTRL_REG_ADDRESS, request);
      fork
        check_tx_frame(8'h53, Periods[speed]);
        send_rx_frame(8'hA6, Periods[speed]);
        begin
          // START protects TX data before busy has asserted as well as during TX.
          write_register(UART_TX_ADDRESS, 16'h00AC);
          attempted_config = config_value;
          attempted_config.uart_speed = uart_speed_t'((speed + 1) % 4);
          attempted_config.parity_bit_enable = 1;
          attempted_config.lsb_first = 0;
          write_register(UART_CTRL_REG_ADDRESS, attempted_config);
          check_read(UART_TX_ADDRESS, 16'h0053);
        end
      join
      repeat (4) tick();
      assert (rx_irq_o);
      check_read(UART_CTRL_REG_ADDRESS, 16'(config_value) | 16'h0004);
      assert (rx_irq_o); // Reading CTRL must not acknowledge RX.
      check_read(UART_RX_ADDRESS, 16'h00A6);
      assert (!rx_irq_o);
      check_read(UART_CTRL_REG_ADDRESS, config_value);

      // Completion wins over an RX read on the same edge.
      fork
        send_rx_frame(8'h3C, Periods[speed]);
        begin
          wait (dut.rx.rx_state == RX_FINISH);
          check_read(UART_RX_ADDRESS, 16'h00A6);
          assert (rx_irq_o);
        end
      join
      check_read(UART_CTRL_REG_ADDRESS, 16'(config_value) | 16'h0004);

      attempted_config = config_value; attempted_config.rx_ie = 0;
      write_register(UART_CTRL_REG_ADDRESS, attempted_config);
      assert (!rx_irq_o);
      check_read(UART_CTRL_REG_ADDRESS, 16'(attempted_config) | 16'h0004);
      write_register(UART_CTRL_REG_ADDRESS, config_value);
      assert (rx_irq_o);
      attempted_config = config_value; attempted_config.uart_enable = 0;
      write_register(UART_CTRL_REG_ADDRESS, attempted_config);
      tick(); assert (!rx_irq_o);
      check_read(UART_CTRL_REG_ADDRESS, 16'(attempted_config) | 16'h0004);
      write_register(UART_CTRL_REG_ADDRESS, config_value);
      assert (rx_irq_o);
      check_read(UART_RX_ADDRESS, 16'h003C); assert (!rx_irq_o);

      // Disable can abort TX and clear START even during an active frame.
      write_register(UART_TX_ADDRESS, 16'h00FF);
      request = config_value; request.start_tx = 1;
      write_register(UART_CTRL_REG_ADDRESS, request);
      @(negedge tx_o); repeat (2 * Periods[speed]) tick();
      write_register(UART_CTRL_REG_ADDRESS, attempted_config);
      tick(); assert (tx_o && !rx_irq_o);
      check_read(UART_CTRL_REG_ADDRESS, attempted_config);
      write_register(UART_CTRL_REG_ADDRESS, config_value);
      repeat (2 * Periods[speed]) begin tick(); assert (tx_o); end

      write_register(UART_CTRL_REG_ADDRESS, request);
      @(negedge tx_o);
      rst = 1; tick();
      assert (tx_o && !rx_irq_o && mmio_read_data_o == 0);
      rst = 0;
      check_read(UART_CTRL_REG_ADDRESS, 16'h0040);
      check_read(UART_TX_ADDRESS, 0);
      check_read(UART_RX_ADDRESS, 0);
    end
    done = 1;
  end
endmodule

module uart_module_tb;
  logic [1:0] done;
  uart_wrapper_check board_clock (.done(done[0]));
  uart_wrapper_check #(.ClockHz(27_000_000)) fast_clock (.done(done[1]));
  initial begin
    $dumpfile("build/tests/uart_module/waveform.fst");
    $dumpvars(0, uart_module_tb);
    wait (&done); $display("UART wrapper tests passed"); $finish;
  end
  initial begin
    #10ms; $fatal(1, "UART wrapper test timeout");
  end
endmodule
