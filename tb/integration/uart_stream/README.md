# UART stream integration test

The SystemVerilog testbench runs the real CPU and interrupt echo firmware at
1.6875 MHz. The Python script generates identical seeded byte sequences for
simulation and hardware: bursts of 16, 256, and 1000 bytes at 9600 baud, 8N1,
without flow control. Both stop at the first failing burst.

## Simulation

Run from the repository root:

```sh
just test uart_stream
just sim uart_stream
just wave uart_stream
```

`sim` generates a waveform and opens Surfer; `wave` reopens it without rerunning.
The test decodes the actual TX pin using an independent baud clock. Its drain
timeout is 100 ms instead of the hardware script's longer timeout.

Useful signals under `uart_stream_tb`: `gpio2_pin_i[1]`, `tx_line`,
`sending_byte`, `echoed_byte`, `sent_count`, `echo_count`, `rx_complete`,
`rx_read`, `rx_overwrite`, `overwrite_count`, `last_rx_read_latency_cycles`,
and `mismatch`. Also inspect `dut.peripheral_manager.uart.uart_ctrl_reg`,
`dut.peripheral_manager.uart.rx_data_reg`, and the TX/RX state machines.

## Hardware

Run the interrupt echo firmware and close picocom before testing:

```sh
python3 tb/integration/uart_stream/uart_stream.py --port /dev/ttyUSB0
```

Use `--sizes 1000 4096` for larger hardware bursts; `--baud` must match firmware.
The script returns a nonzero exit status on failure. The software RX queue
passed all three default bursts on hardware; sustained input can still fill it.
