# Character RAM demo

`char_demo.hex` contains 2400 16-bit cells in row-major order (80×30).
Bits 15:8 are the glyph code, 7:4 foreground, and 3:0 background.
Each 256-cell pass uses glyph codes 1 through 255, then 0 (the 256th glyph).
The first pass is black on white; the second is white on black. Remaining
cells use independently randomized foreground/background palette indices,
generated with seed 20261014. Equal colors are possible and hide that glyph.

The CPU board top selects this example via `HDMI_CHAR_INIT_FILE` for temporary
display bring-up. Initialization occurs at FPGA configuration/simulation
startup; a button reset does not restore the contents. CPU writes still work.
Use an empty initialization path to return to uninitialized character RAM.
