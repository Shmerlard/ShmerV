#!/usr/bin/env python3
"""Convert a raw VGA bitmap font (256 glyphs) to readmemh byte data."""

import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font", type=Path, help="raw binary font, e.g. NICER40C.F16")
    parser.add_argument("output", type=Path, help="output hex file")
    args = parser.parse_args()

    if args.font.resolve() == args.output.resolve():
        parser.error("input and output must be different files")

    try:
        data = args.font.read_bytes()
        if not data or len(data) % 256 or not 1 <= len(data) // 256 <= 32:
            parser.error("expected 256 glyphs, each containing 1–32 bytes (one byte per row)")
        # Preserve glyph order, row order, and bit order exactly as supplied.
        args.output.write_text("".join(f"{byte:02X}\n" for byte in data), encoding="ascii")
    except OSError as error:
        parser.error(str(error))

    print(f"Wrote {len(data)} bytes: 256 glyphs, 8×{len(data) // 256} pixels")


if __name__ == "__main__":
    main()
