# Standalone HDMI test

See [THIRD_PARTY.md](THIRD_PARTY.md) for source attribution and license notices.

Standalone 640x480 at 60 Hz DVI-compatible video over the HDMI connector,
without the CPU or GPIO peripherals. No audio or HDMI data islands.

- Input clock: 27 MHz, pin 52.
- Reset: onboard S1, active-low, pin 4.
- Onboard S2, active-low, pin 3: hold to show the original palette, release to
  resume animation. Input uses two synchronization registers, no software/RTL
  debounce (hardware debounce assumed).
- TMDS clock P/N: 69/68.
- TMDS data 0 P/N: 71/70 (blue and sync control).
- TMDS data 1 P/N: 73/72 (green).
- TMDS data 2 P/N: 75/74 (red).

Pin pairing and drive settings follow Sipeed's HDMI example:
https://github.com/sipeed/TangNano-9K-example/blob/main/hdmi/src/hdmi.cst

The timing module implements 640x480 with 800x525 total periods and exposes
x/y coordinates and active_video. The pixel generator repeats red horizontally
and green vertically every 256 positions, with blue zero and black outside
active video.

The TMDS encoder implements transition reduction, running disparity, and the
four blanking control symbols. Its output is registered with one pixel-clock
latency; downstream control/data alignment must account for that latency.
Reset is synchronous and emits control 00. Blanking clears running disparity.

The top now displays images/shmerv.png, a 320x240 indexed 16-color image,
enlarged 2x. The synchronous four-bit image ROM consumes 37.5 KiB logically;
actual block RAM allocation depends on synthesis packing. Precomputed HSV hue
palettes occupy another 12 KiB, in three synchronous 4096x8 channel banks.
Active-video and both sync signals are delayed two pixel clocks to match
the index and palette ROMs; the encoder adds another cycle.
The gradient generator remains available but is not connected to the top.

Animation rotates HSV hue through a full circle in 720 frames (12 seconds at
60 Hz), preserving saturation and value to eight-bit rounding precision.
There are 256 palette steps, advancing every two or three frames.
Phase updates at the end of the visible frame, during vertical blanking, and
pauses while S2 is held. Hue zero preserves the original palette exactly.
Hue is pipelined with the ROM's control signals. The logical ROM footprint
is 49.5 KiB; inspect actual block RAM packing in the user-run synthesis report.

Regenerate the ROM data from the repository root after changing the indexed PNG:

```sh
node scripts/software/indexed_png_to_rom.mjs \
  fpga/tang_nano_9k/hdmi_test/images/shmerv.png \
  fpga/tang_nano_9k/hdmi_test/images/shmerv
```

The top's initialization paths are relative to this Gowin project directory.
When simulating from the repository root, override PIXEL_INIT_FILE and
HUE_PALETTE_PREFIX with repository-relative paths, as the testbenches do.

The top connects timing, image ROM, three encoders, and four OSER10 serializers.
Data lane 0 is blue with {vsync, hsync} during blanking; lanes 1/2 are green/red.
Sync is active-low. The clock serializer repeats 1111100000, bit 0 first.
All serializers use the same clocks/reset and therefore share output latency.

clocks.sv uses rPLL: 27 MHz * 14 / 3 = 126 MHz (1008 MHz VCO), followed
by dedicated CLKDIV /5 for 25.2 MHz. Reset asserts asynchronously on button
press or PLL lock loss, and releases through four pixel-clock registers.
Editor primitive declarations in config/editor are not FPGA sources.

Open hdmi_test.gprj for the separate Gowin project.
The existing open-source target discovery also recognizes hdmi_test.
Only the user runs FPGA builds or programming. In Gowin, inspect clock.sdc
resolution: serializer_clk must be 126 MHz and pixel_clk 25.2 MHz; check setup
and hold closure before programming. These generated clocks target primitive
output pins; verify the pin names resolve in the synthesized design.
The open-source script does not read clock.sdc and its 27 MHz default alone
does not verify the new clock domains. Use the Gowin project for initial
bring-up; open-source timing constraints and project-relative ROM initialization
paths remain to be adapted before using that script for this image target.

tb/fpga/hdmi_test_top_tb.sv checks this top with Gowin's gw1n/prim_sim.v
library, including clock periods, serialized RGB and bit order, and reset.
It is not included in FPGA sources. Physical timing and monitor compatibility
still require the user's FPGA build and board test.
