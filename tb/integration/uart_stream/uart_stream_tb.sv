timeunit 1ns / 1ps;

// CPU-system integration test with independent 9600-baud sender/receiver.
module uart_stream_tb;
  import uart_types::*;
  localparam int ClockHz = 1_687_500;
  localparam realtime ClockPeriod = 1.0e9 / ClockHz;
  localparam realtime BitPeriod = 1.0e9 / 9600;
  localparam int BurstSizes[3] = '{16, 256, 1000};

  logic clk = 0, rst = 1;
  logic [7:0] gpio2_pin_i = 8'h02;
  wire [7:0] gpio2_pin_o, gpio2_pin_oe_o;
  logic [7:0] input_bytes[1272];
  logic [7:0] echo_bytes[1272];
  int burst_index = 0, input_offset = 0;
  int sent_count = 0, echo_count = 0, rx_count = 0, rx_read_count = 0;
  int overwrite_count = 0;
  int last_rx_read_latency_cycles = 0, max_rx_read_latency_cycles = 0;
  int cycle_count = 0, last_rx_cycle = 0;
  logic rx_complete, rx_read, rx_overwrite;
  logic tx_line;
  logic [7:0] sending_byte = 0, echoed_byte = 0;
  logic mismatch = 0;
  int first_mismatch = -1;

  always #(ClockPeriod / 2) clk = ~clk;
  assign tx_line = gpio2_pin_o[0];
  assign rx_complete = dut.peripheral_manager.uart.rx.rx_state == RX_FINISH;
  assign rx_read = dut.peripheral_manager.uart.read_from_rx_addr;
  assign rx_overwrite = rx_complete &&
      dut.peripheral_manager.uart.uart_ctrl_reg.rx_ifg && !rx_read;

  cpu_system #(
      .MEM_WORDS(4096), .CLOCK_HZ(ClockHz),
      .RESET_PC(32'h80000000), .RAM_BASE_ADDRESS(32'h80000000),
      .MEMORY_INIT_FILE("build/tests/uart_stream/firmware/program.hex"),
      .MEMORY_INIT_FILE_LANE0("build/tests/uart_stream/firmware/program_lane0.hex"),
      .MEMORY_INIT_FILE_LANE1("build/tests/uart_stream/firmware/program_lane1.hex"),
      .MEMORY_INIT_FILE_LANE2("build/tests/uart_stream/firmware/program_lane2.hex"),
      .MEMORY_INIT_FILE_LANE3("build/tests/uart_stream/firmware/program_lane3.hex")
  ) dut (
      .clk(clk), .rst(rst),
      .gpio0_pin_i(8'b0), .gpio0_pin_o(), .gpio0_pin_oe_o(),
      .gpio1_pin_i(8'b0), .gpio1_pin_o(), .gpio1_pin_oe_o(),
      .gpio2_pin_i(gpio2_pin_i), .gpio2_pin_o(gpio2_pin_o),
      .gpio2_pin_oe_o(gpio2_pin_oe_o), .address_overlap_o()
  );

  always @(posedge clk) if (!rst) begin
    cycle_count++;
    if (rx_read) begin
      rx_read_count++;
      last_rx_read_latency_cycles = cycle_count - last_rx_cycle;
      if (last_rx_read_latency_cycles > max_rx_read_latency_cycles)
        max_rx_read_latency_cycles = last_rx_read_latency_cycles;
    end
    if (rx_complete) begin
      rx_count++;
      last_rx_cycle = cycle_count;
    end
    if (rx_overwrite) begin
      overwrite_count++;
      $display("RX overwrite: burst %0d, RX frame %0d at %.3f ms",
               burst_index, rx_count - 1, $realtime / 1.0e6);
    end
  end

  // Decode actual TX pin transitions rather than inspecting the TX data register.
  initial begin
    wait (!rst);
    wait (gpio2_pin_oe_o[0]);
    forever begin
      @(negedge tx_line);
      #(BitPeriod / 2);
      assert (!tx_line) else $fatal(1, "Invalid echoed start bit");
      for (int bit_index = 0; bit_index < 8; bit_index++) begin
        #(BitPeriod);
        echoed_byte[bit_index] = tx_line;
      end
      #(BitPeriod);
      assert (tx_line) else $fatal(1, "Invalid echoed stop bit");
      assert (echo_count < 1272) else $fatal(1, "Too many echo bytes");
      echo_bytes[echo_count] = echoed_byte;
      if (echo_count >= BurstSizes[burst_index] ||
          echoed_byte != input_bytes[input_offset + echo_count]) begin
        mismatch = 1;
        if (first_mismatch == -1) first_mismatch = echo_count;
      end
      echo_count++;
    end
  end

  initial begin
    $dumpfile("build/tests/uart_stream/waveform.fst");
    $dumpvars(0, uart_stream_tb);
    $readmemh("build/tests/uart_stream/input.hex", input_bytes);
    repeat (5) @(negedge clk);
    rst = 0;
    wait (dut.peripheral_manager.uart.uart_ctrl_reg.uart_enable);
    repeat (20) @(negedge clk);

    for (burst_index = 0; burst_index < 3; burst_index++) begin
      echo_count = 0;
      rx_count = 0;
      rx_read_count = 0;
      overwrite_count = 0;
      max_rx_read_latency_cycles = 0;
      mismatch = 0;
      first_mismatch = -1;
      for (sent_count = 0; sent_count < BurstSizes[burst_index]; sent_count++) begin
        sending_byte = input_bytes[input_offset + sent_count];
        gpio2_pin_i[1] = 0;
        #(BitPeriod);
        for (int bit_index = 0; bit_index < 8; bit_index++) begin
          gpio2_pin_i[1] = sending_byte[bit_index];
          #(BitPeriod);
        end
        gpio2_pin_i[1] = 1;
        #(BitPeriod);
      end
      // No further input: allow pending RX, ISR and TX work to drain.
      // Shorter than the script's timeout to keep the waveform focused.
      #20ms;
      $display("Burst %0d: sent=%0d echoed=%0d RX=%0d reads=%0d overwrites=%0d max read delay=%0d cycles",
               burst_index, sent_count, echo_count, rx_count, rx_read_count,
               overwrite_count, max_rx_read_latency_cycles);
      if (mismatch || echo_count != BurstSizes[burst_index]) begin
        if (first_mismatch >= 0)
          $display("First mismatch at byte %0d: expected %02x, received %02x",
                   first_mismatch, input_bytes[input_offset + first_mismatch],
                   echo_bytes[first_mismatch]);
        $fatal(1, "Continuous UART echo failed; inspect waveform at rx_overwrite");
      end
      $display("PASS: %0d bytes echoed exactly", sent_count);
      input_offset += BurstSizes[burst_index];
    end
    $finish;
  end

  initial begin
    #2s;
    $fatal(1, "UART stream watchdog timeout");
  end
endmodule
