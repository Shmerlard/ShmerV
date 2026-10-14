# CPU system

Tang Nano 9K SoC: 16 KiB RAM, a 6.75 MHz CPU (27 MHz / 4), GPIO B/C, UART,
Timer A, and 640×480 HDMI text output. GPIO A's upper pins are relocated
to 48/49 so the HDMI clock can use 69/68.

`ENABLE_HDMI` is a build-time parameter on the top, `soc`, and
`peripheral_manager` (default: enabled). Setting it to `0` omits HDMI clocking,
serializers, output buffers, and display memories. HDMI MMIO reads return zero,
writes are ignored, and HDMI outputs are held low. GPIO pin assignments stay fixed.

`hdmi_board_output_tb.sv` checks Gowin clocking and serializers separately;
it requires vendor simulation models and is excluded from `just test`.

## Build and load

```sh
just firmware-build PROGRAM
just fpga-build soc PROGRAM
just fpga-repack soc PROGRAM
just fpga-repack soc PROGRAM --gowin
just fpga-flash soc PROGRAM
```

The default build/repack flow uses Yosys/nextpnr. For Gowin, build firmware,
then run IDE synthesis, `just gowin-fix-memory`, and PNR.
Subsequent firmware-only changes can use `repack --gowin` without synthesis/PNR.

Gowin repack requires matching `impl/pnr/ShmerV.fs` and
`impl/gwsynthesis/ShmerV.vg`. It updates the eight CPU RAM blocks and preserves
routing, other memories, and the original FS. Output:
`build/fpga/tang_nano_9k/soc/images/PROGRAM.fs`.
Supported images are uncompressed, unencrypted, CRC-enabled GW1NR-9C files
with eight 4096×4 CPU RAM blocks. Invalid CRCs, ambiguous RAM matches,
oversized firmware, and hardware newer than the FS are rejected.
The timestamp check is not a saved build fingerprint; retain files from the same build.
Only the user runs FPGA builds and programming.

## Pins

| Function | Board pins |
|---|---|
| Oscillator / reset S1 | 52 / 4 (active-low reset) |
| GPIO A bits 0–7 | 51, 53, 54, 55, 56, 57, 48, 49 |
| GPIO B bits 0–7 | 29, 30, 33, 34, 40, 35, 41, 42 |
| GPIO C bits 0–7 | 38, 37, 36, 39, 25, 26, 27, 28 |
| UART TX / RX | C.0 (38) / C.1 (37) |
| TMDS clock P/N | 69/68 |
| TMDS blue / green / red P/N | 71/70, 73/72, 75/74 |

All three GPIO ports are bidirectional through `DIR`.
Peripheral addresses are defined in `shmerv_memory_map.h`;
HDMI memory layout is documented in the [HDMI README](../../../rtl/peripherals/hdmi/README.md).

## Clocks and reset

`INPUT_CLOCK_HZ=27000000` and power-of-two `CLOCK_DIVIDE=4` set the CPU rate.
The divided clock uses a separate output register; its frequency propagates to UART.
UART requires at least four CPU clocks per bit at every supported speed.

HDMI assumes a fixed 27 MHz input: rPLL produces 126 MHz, and CLKDIV /5
produces 25.2 MHz. Pixel reset asserts on button reset or PLL lock loss and
releases after four pixel-clock edges.

Both flows use `pins.cst`; `clock_gowin.cst` and `clock_nextpnr.cst` request
global CPU clock routing. Update frequency constraints when changing clocks.
Explicit HDMI SDC constraints and dual-clock RAM/reset review remain pending;
frequency PASS alone does not establish complete timing closure.

## Programs

Programs live in [sw/programs](../../../sw/programs/). See their local READMEs:
[hdmi_hello](../../../sw/programs/hdmi_hello/README.md),
[uart_hdmi](../../../sw/programs/uart_hdmi/README.md),
[interrupt_test_1](../../../sw/programs/interrupt_test_1/README.md), and
[uart_hello](../../../sw/programs/uart_hello/README.md).
`gpio_pattern` alternates LED bytes; `gpio_nibble_sum` sums switch nibbles.

The board currently initializes character RAM from
[char_demo.hex](../../../rtl/peripherals/hdmi/examples/char_demo.hex).
CPU writes replace it; button reset does not reload it.
An empty `HDMI_CHAR_INIT_FILE` disables initialization.

See [third-party credits](../../../docs/third-party.md).
