# HDMI text display

640×480 video with 80×30 cells, an 8×16 font, and a fixed 16-color VGA palette.
The CPU and renderer access character RAM on separate clocks. Board clocking,
pins, and loading commands are in the [CPU target README](../../../fpga/tang_nano_9k/soc/README.md).

## Memories and MMIO

| Memory | Contents | Size | CPU address |
|---|---|---|---|
| Character RAM | 4080 cells: character byte + foreground/background nibbles | 8160 bytes | `0x10006000 + 4*(row*80 + column)` |
| Font ROM | 256 glyphs × 16 row bytes | 4096 bytes | No MMIO |
| Palette | 16 fixed RGB colors | 48 bytes of constants | No MMIO |

Cell bits 15:8 select the glyph, 7:4 foreground, and 3:0 background.
For example, `0x41F0` is A, white on black. Each aligned four-byte slot
returns its cell in bits 15:0; writes must enable both low bytes.
Upper bytes are ignored. Byte writes and unaligned slots are unsupported.
The word stride uses 16320 address bytes but only 8160 bytes of RAM.
The last cell slot is `0x10009FBC`.

`hdmi_module` connects the existing register logic, character memory, text
renderer, and video output. The register interface is still incomplete;
no new controller behavior is implemented by this reorganization.

The initial write interface now supports direct cell writes at
`0x10006000 + 4*index`, cursor-position writes at `0x10002004` (low 12 bits),
and cell writes at `0x1000200C` using the current cursor with auto-increment.
Setting the cursor does not write RAM. CTRL writes update cursor enable,
blink, interrupt enable, and the overflow flag. Writing the last cell through
CURSOR_DATA wraps the cursor to zero and sets the sticky overflow flag on
the following CPU clock. A new overflow wins over a simultaneous CTRL write.
Software clears the flag by writing its bit as zero while preserving settings.
Explicit cursor-position writes outside `0..TEXT_COLUMNS*TEXT_BUFFER_ROWS-1`
are ignored; all 16 input bits are checked before selecting the 12-bit index.

Reads respond after one CPU clock, with no extra cycle for character RAM.
Results are zero-extended to the 32-bit bus and held until the next read.

| Address | Read result |
|---|---|
| `0x10002000` CTRL | Current control bits; reset value `0x001C` |
| `0x10002004` CURSOR_POS | Current 12-bit cell index, zero-extended |
| `0x10002008` START_ROW | Zero: window start remains fixed |
| `0x1000200C` CURSOR_DATA | Not intended for reading; retains the last register response |
| Character RAM slots | Stored 16-bit cell |
| Reserved HDMI slots | Retain the last register response |
| Invalid/unaligned slots | Zero (rejected by the manager) |

CTRL bit order currently follows `hdmi_ctrl_reg_t`: enable at bit 4,
cursor enable at bit 3, blink at bit 2, overflow flag at bit 1, IRQ enable at bit 0.
START_ROW remains fixed at zero. Clearing display enable blanks RGB, stops
renderer memory requests, and clears its row caches; RAM and video timing
remain active. Setting it resumes rendering. `hdmi_module.irq_o` exposes enabled overflow;
the peripheral manager routes it below the existing interrupt sources as custom
cause 24 (`mcause=0x80000018`). Firmware can define a handler with
`SHMERV_INTERRUPT(SHMERV_IRQ_HDMI_OVERFLOW, handler)`; the runtime includes
the corresponding vector and a default unhandled-interrupt handler.
See `sw/include/shmerv_hdmi.h` for offsets, masks, and access semantics.

- `hdmi_char_memory` contains only dual-clock character storage and CPU/display ports.
- `hdmi_text_renderer` owns the pixel generator, one font ROM with its palette,
  and the blink module. It substitutes a white-on-black underscore for the
  visible cursor without modifying RAM, retaining the one-clock RAM response.
- `hdmi_video_output` owns the timer and three TMDS encoders. It supplies
  coordinates/active-video to the renderer and encodes its RGB output.

The cursor remains enabled and blinking at its controller-managed position,
with 500 ms visible/hidden intervals at the configured CPU clock. Its existing
CPU-to-pixel clock sampling is unchanged. The temporary CPU font window remains removed.

## Rendering

The timer and generator share `WINDOW_OFFSET=5` (supported 4–7).
At raw X=`8*N`, the generator requests cell N, then its font row.
Two 7-byte caches hold bitmap/foreground/background for the current and next
cell. The prepared cache becomes current before X=`8*N+WINDOW_OFFSET`.
Bit 7 is the leftmost pixel; palette lookup is combinational.

TMDS channels 0/1/2 carry blue/green/red. Blue also carries active-low sync;
the encoders add one pixel-clock delay. Disabling the generator produces
black video while timing continues.

Character RAM now allocates 80×51 cells (8160 bytes); the visible area and
existing MMIO mapping remain unchanged. Window scrolling is not implemented.
Both RAM ports use linear 12-bit cell indices; all 51 rows are addressable.
Character RAM optionally loads `INIT_FILE` at configuration, never on reset.
The board currently selects [char_demo.hex](examples/char_demo.hex).
CPU writes replace its contents normally.

## Font conversion

`FONT_FILE` selects the synchronous ROM's hex file. Paths are relative to
the tool's working directory; defaults assume the repository root.

```sh
python3 scripts/software/font_to_hex.py rtl/peripherals/hdmi/fonts/NICER40C.F16 rtl/peripherals/hdmi/fonts/NICER40C.hex
```

The converter preserves byte/bit order and accepts 256 glyphs, 8 pixels wide,
1–32 rows high. An 8×16 glyph row has ROM address `{char_code, row}`.

See [credits and license notices](../../../docs/third-party.md).
