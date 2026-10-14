# HDMI text display

640×480 video with 80×30 cells, an 8×16 font, and a fixed 16-color VGA palette.
The CPU and renderer access character RAM on separate clocks. Board clocking,
pins, and loading commands are in the [CPU target README](../../../fpga/tang_nano_9k/cpu_system/README.md).

## Memories and MMIO

| Memory | Contents | Size | CPU address |
|---|---|---|---|
| Character RAM | 2400 cells: character byte + foreground/background nibbles | 4800 bytes | `0x10002000 + 4*(row*80 + column)` |
| Font ROM | 256 glyphs × 16 row bytes | 4096 bytes | No MMIO |
| Palette | 16 fixed RGB colors | 48 bytes of constants | No MMIO |

Cell bits 15:8 select the glyph, 7:4 foreground, and 3:0 background.
For example, `0x41F0` is A, white on black. Each aligned four-byte slot
returns its cell in bits 15:0; writes must enable both low bytes.
Upper bytes are ignored. Byte writes and unaligned slots are unsupported.
The word stride uses 9600 address bytes but only 4800 bytes of RAM.
The last cell slot is `0x1000457C`.

`hdmi_module` owns one font ROM and palette, accessed by the generator through
request/response ports. The temporary CPU font window was removed.
Control registers are not implemented.

## Rendering

The timer and generator share `WINDOW_OFFSET=5` (supported 4–7).
At raw X=`8*N`, the generator requests cell N, then its font row.
Two 7-byte caches hold bitmap/foreground/background for the current and next
cell. The prepared cache becomes current before X=`8*N+WINDOW_OFFSET`.
Bit 7 is the leftmost pixel; palette lookup is combinational.

TMDS channels 0/1/2 carry blue/green/red. Blue also carries active-low sync;
the encoders add one pixel-clock delay. Disabling the generator produces
black video while timing continues.

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
