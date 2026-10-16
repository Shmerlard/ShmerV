#!/usr/bin/env python3
"""Create an SVG chart of all 256 glyphs in an 8-pixel-wide bitmap font."""

import argparse
from html import escape
from pathlib import Path
import re


def read_font(path, file_format):
    if file_format == "hex":
        source = path.read_text(encoding="ascii")
        source = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.S)
        tokens = source.split()
        if any(not re.fullmatch(r"[0-9a-fA-F]{1,2}", token) for token in tokens):
            raise ValueError("hex input must contain sequential byte values (no addresses or X/Z)")
        data = bytes(int(token, 16) for token in tokens)
    else:
        data = path.read_bytes()
    if not data or len(data) % 256 or not 1 <= len(data) // 256 <= 32:
        raise ValueError("expected 256 glyphs, 8 pixels wide and 1–32 rows high")
    return data, len(data) // 256


def make_chart(data, height, name, scale):
    cell_width = max(92, 8 * scale + 24)
    cell_height = height * scale + 54
    margin, header = 24, 80
    width = 2 * margin + 16 * cell_width
    total_height = header + 16 * cell_height + margin
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{total_height}" '
        f'viewBox="0 0 {width} {total_height}">',
        f'<title>{escape(name)} — 256-glyph font chart</title>',
        '<desc>Each cell shows the actual bitmap, its hexadecimal byte code, and decimal code. '
        'Rows follow the high hex digit; columns follow the low hex digit.</desc>',
        '<style>text{font-family:monospace;fill:#e5e7eb}.code{font-size:14px}'
        '.decimal{font-size:11px;fill:#9ca3af}</style>',
        f'<rect width="{width}" height="{total_height}" fill="#111827"/>',
        f'<text x="{margin}" y="30" font-size="20">{escape(name)} · 8×{height} · 256 glyphs</text>',
        f'<text x="{margin}" y="54" font-size="13">Hex code / decimal · '
        'row = high hex digit, column = low hex digit · bit 7 is leftmost</text>',
    ]
    for code in range(256):
        x = margin + (code % 16) * cell_width
        y = header + (code // 16) * cell_height
        glyph_x = x + (cell_width - 8 * scale) // 2
        glyph_y = y + 8
        parts += [
            f'<g id="glyph-{code:02X}"><title>0x{code:02X} / {code}</title>',
            f'<rect x="{x}" y="{y}" width="{cell_width}" height="{cell_height}" '
            'fill="none" stroke="#374151"/>',
            f'<rect x="{glyph_x}" y="{glyph_y}" width="{8 * scale}" '
            f'height="{height * scale}" fill="#000000"/>',
        ]
        for row in range(height):
            bitmap = data[code * height + row]
            for column in range(8):
                if bitmap & (0x80 >> column):
                    parts.append(
                        f'<rect x="{glyph_x + column * scale}" y="{glyph_y + row * scale}" '
                        f'width="{scale}" height="{scale}" fill="#ffffff"/>'
                    )
        center = x + cell_width // 2
        label_y = glyph_y + height * scale + 19
        parts += [
            f'<text class="code" x="{center}" y="{label_y}" text-anchor="middle">0x{code:02X}</text>',
            f'<text class="decimal" x="{center}" y="{label_y + 16}" text-anchor="middle">{code}</text>',
            '</g>',
        ]
    return "\n".join(parts + ['</svg>', ''])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font", type=Path, help="sequential .hex bytes or raw binary font")
    parser.add_argument("output", type=Path, help="output .svg file")
    parser.add_argument("--format", choices=("auto", "hex", "raw"), default="auto",
                        help="auto selects hex for .hex files, raw otherwise")
    parser.add_argument("--scale", type=int, default=4, help="pixel size, 1–16 (default: 4)")
    args = parser.parse_args()
    if args.font.resolve() == args.output.resolve():
        parser.error("input and output must be different files")
    if args.output.suffix.lower() != ".svg":
        parser.error("output must have the .svg extension")
    if not 1 <= args.scale <= 16:
        parser.error("scale must be between 1 and 16")
    file_format = args.format
    if file_format == "auto":
        file_format = "hex" if args.font.suffix.lower() == ".hex" else "raw"
    try:
        data, height = read_font(args.font, file_format)
        chart = make_chart(data, height, args.font.name, args.scale)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(chart, encoding="utf-8")
    except (OSError, ValueError, UnicodeError) as error:
        parser.error(str(error))
    print(f"Wrote {args.output}: 256 glyphs, 8×{height}, hexadecimal and decimal codes")


if __name__ == "__main__":
    main()
