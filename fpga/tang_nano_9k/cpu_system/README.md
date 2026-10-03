# CPU system

Runs a program from `sw/programs/` on the complete FPGA system.

```sh
just fpga-build cpu_system PROGRAM
just fpga-repack cpu_system PROGRAM
just fpga-flash cpu_system PROGRAM
```

- `gpio_pattern`: alternate the LEDs between `0xAA` and `0x55`.
- `gpio_nibble_sum`: add the DIP-switch nibbles and show the result on the LEDs.
- `interrupt_test_1`: count presses of the active-low A.0 / pin 51 button on
  all eight Port C LEDs in binary, starting at zero and wrapping after 255.
  Interrupts are re-enabled after approximately 20 ms of stable button release.
- `uart_hello`: count from `0x00` to `0xFF` on Port A, then repeatedly transmit
  `Hello` on GPIO2.0 / pin 38 at 9600 baud.

- Reset: onboard button S1, pin 4, active-low.
- GPIO0 / Port A: `0x10000000`, pins 51, 53, 54, 55, 56, 57, 68, 69 (bits 0–7).
- GPIO1 / Port B: `0x10000100`, pins 29, 30, 33, 34, 40, 35, 41, 42 (bits 0–7).
- GPIO2 / Port C: `0x10000200`, pins 38, 37, 36, 39, 25, 26, 27, 28 (bits 0–7).
- RAM: 16 KiB.

All three GPIO ports are bidirectional; software controls them through `DIR`.

The board wrapper has `INPUT_CLOCK_HZ = 27_000_000` and `CLOCK_DIVIDE = 32`
parameters. The divider supports powers of two >= 2, with 50% duty cycle.
The reported frequency is truncated to whole Hz if necessary.
`INPUT_CLOCK_HZ` describes the physical oscillator; it does not change it.
The resulting `CLOCK_HZ` is passed through the SoC and peripheral manager to
UART. UART rounds `CLOCK_HZ / BAUD_RATE` to the nearest whole cycle; the defaults
give 843.75 kHz and 88 cycles per bit at 9600 baud. `UART_BAUD_RATE` can be set
on `cpu_system`; the UART requires at least one clock cycle per bit.

When changing either clock parameter, update `clock.sdc`'s primary period and
generated-clock divide ratio. For nextpnr, keep frequency constraints consistent
and update `pins.cst`'s clock net to `clock_divider[log2(CLOCK_DIVIDE)-1]`
(for example `[3]` for divide-by-16). Check its BUFG routing in the user-run build.
These constraint files are not generated
from RTL parameters. Software busy-loop delays also require recalibration.

The board divider and UART frequency propagation simulation is
`tb/fpga/cpu_system_top_tb.sv`. Run it without synthesizing or programming:

```sh
verilator --binary --assert --timing --timescale-override 1ns/1ns \
  -Wno-TIMESCALEMOD --top-module cpu_system_top_tb \
  --Mdir build/tests/board_clock/obj -o board_clock_test \
  -f fpga/tang_nano_9k/cpu_system/sources.f tb/fpga/cpu_system_top_tb.sv
build/tests/board_clock/obj/board_clock_test
```

Gowin uses `clock.sdc` to constrain both clocks. Check the generated-clock constraint
resolves and setup/hold timing passes after rebuilding; the RTL change requires
synthesis, not only P&R.

For the open-source flow, `pins.cst` requests global clock routing for
`clock_divider[4]` with `CLOCK_LOC ... BUFG = CLK`. This is nextpnr's net name
for the divided CPU clock. The build also enables `--detailed-timing-report`
in `report.json`. After a full build, check `nextpnr.log` for the buffered
clock routing result, missing-net or routing errors, and `Hold/min time`
violations. A frequency PASS alone does not establish hold timing closure.
With the fixed divide-by-32 implementation and this clock-routing constraint,
the user observed working GPIO interrupt
counting with normal GPIO-controlled output enable on all Port C pins. The
firmware and synthesized netlist were byte-identical to the preceding failing
build; the routed design now contains a BUFG and global clock wires. This
supports a clock-distribution issue, but does not establish a specific hold
violation. FPGA builds and programming are run by the user.
