# Standalone HDMI image test

640×480 at 60 Hz over the HDMI connector, without the CPU.
Video is DVI-compatible: no audio or HDMI data islands.
Open `hdmi_test.gprj` for the separate Gowin target.

Standalone image, hue, timer, and top simulation benches live here and are
excluded from the regular `just test` suite.

## Hardware

- Input clock: 27 MHz, pin 52.
- S1 reset: active-low, pin 4.
- S2: active-low, pin 3; hold for original colors, release to resume animation.
- TMDS clock P/N: 69/68.
- Blue/sync, green, red P/N: 71/70, 73/72, 75/74.

The PLL produces 126 MHz; CLKDIV /5 produces 25.2 MHz.
Reset asserts on button/PLL lock loss and releases through four pixel-clock
registers. Four OSER10s serialize bit 0 first; the clock symbol is 1111100000.
Timing totals are 800×525 with active-low sync.

## Image and animation

`images/shmerv.png` is a 320×240 indexed image enlarged 2×.
Its 4-bit index ROM uses 37.5 KiB; hue palettes add 12 KiB.
Active/sync signals are delayed two pixel clocks with the ROM data;
TMDS encoding adds one more clock. Actual BSRAM packing is tool-dependent.

HSV hue rotates through 256 steps over 720 frames (12 seconds).
S2 pauses phase and selects the original colors. Frame updates occur in blanking.
The older gradient generator remains available but is not connected.

Regenerate data from the repository root:

```sh
node scripts/software/indexed_png_to_rom.mjs \
  fpga/tang_nano_9k/hdmi_test/images/shmerv.png \
  fpga/tang_nano_9k/hdmi_test/images/shmerv
```

Top initialization paths are relative to the Gowin project directory.
Repository-root simulations must override `PIXEL_INIT_FILE` and
`HUE_PALETTE_PREFIX`.

## Verification

`hdmi_test_top_tb.sv` uses the separately installed Gowin
`gw1n/prim_sim.v` to check clocks, serialized RGB, bit order, and reset.
Declaration stubs in `fpga/gowin/primitives_stub.sv` are for code diagnostics
only; exclude them from synthesis and simulation.

Only the user runs FPGA builds/programming. Check generated clocks and
setup/hold timing in Gowin. The open-source script's input-clock constraint
alone does not constrain HDMI clocks; its constraints and ROM paths still
need adaptation for this target.

See [credits and license notices](../../../docs/third-party.md).
