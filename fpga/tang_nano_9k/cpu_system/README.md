# CPU system

Runs a program from `sw/programs/` on the complete FPGA system.

```sh
just fpga-build cpu_system PROGRAM
just fpga-repack cpu_system PROGRAM
just fpga-flash cpu_system PROGRAM
```

- `gpio_pattern`: alternate the LEDs between `0xAA` and `0x55`.
- `gpio_nibble_sum`: add the DIP-switch nibbles and show the result on the LEDs.
- `uart_hello`: count from `0x00` to `0xFF` on Port A, then repeatedly transmit
  `Hello` on GPIO2.0 / pin 51 at 9600 baud.

- Reset: onboard button S1, pin 4, active-low.
- GPIO0 / Port A: `0x10000000`, pins 25–30, 33, and 34.
- GPIO1 / Port B: `0x10000100`, pins 70–77.
- GPIO2 / Port C: `0x10000200`, pins 51, 53–57, 68, and 69.
- RAM: 16 KiB.

Both GPIO ports are bidirectional; software controls them through `DIR`.

The board wrapper divides the 27 MHz oscillator to 843.75 kHz for the CPU and
peripherals. Gowin uses `clock.sdc` to constrain both clocks. UART uses 88 cycles
per bit for approximately 9600 baud. Check the generated-clock constraint
resolves and setup/hold timing passes after rebuilding; the RTL change requires
synthesis, not only P&R.
