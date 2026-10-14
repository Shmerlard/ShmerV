#!/usr/bin/env python3
"""Replace only CPU RAM initialization in an uncompressed GW1N-9C Gowin FS.

BSRAM fuse layout and frame CRC reference: Project Apicula,
https://github.com/YosysHQ/apicula (gowin_pack.py and bslib.py).
No synthesis, placement, routing, or logic-fuse changes are performed.
"""
import argparse
import importlib.resources
from pathlib import Path
import re


def crc16(data):
    crc = 0
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ (0xA001 if crc & 1 else 0)
    return crc


def read_frames(text):
    lines = text.splitlines()
    for required in ["//Device: GW1NR-9", "//Device Version: C",
                     "//Compress: OFF", "//Encryption: OFF", "//CRCCheck: ON"]:
        if required not in lines:
            raise ValueError(f"Unsupported FS: missing {required}")
    binary = [(i, line) for i, line in enumerate(lines) if line and not line.startswith("//")]
    header_end = next((n for n, (_, bits) in enumerate(binary)
                       if len(bits) == 32 and bits[:8] == "00111011"), None)
    if header_end is None:
        raise ValueError("Missing FS frame-count command")
    count = int(binary[header_end][1][16:], 2)
    frames = binary[header_end + 1:header_end + 1 + count]
    if len(frames) != count or not frames:
        raise ValueError("Truncated FS frames")
    prefix = bytearray()
    for _, bits in binary[3:header_end + 1]:
        raw = int(bits, 2).to_bytes(len(bits)//8, "big")
        if raw[0] != 0xD2:
            prefix.extend(raw)
    for _, bits in frames:
        if len(bits) % 8 or set(bits) - {"0", "1"} or len(bits) < 72:
            raise ValueError("Malformed FS frame")
        raw = int(bits, 2).to_bytes(len(bits)//8, "big")
        if crc16(prefix + raw[:-8]) != int.from_bytes(raw[-8:-6], "little"):
            raise ValueError("FS frame CRC mismatch")
        prefix = bytearray(raw[-6:])
    return lines, frames


def cpu_ram_bits(netlist):
    result = {}
    for lane in range(4):
        for bank in range(2):
            name = f"memory_lane{lane}_memory_lane{lane}_0_{bank}_s"
            if not re.search(r"\bDPB\s+" + re.escape(name) + r"\s*\(", netlist):
                raise ValueError(f"Missing expected CPU DPB {name}")
            for port in (0, 1):
                if not re.search(r"defparam\s+" + re.escape(name)
                                 + rf"\.BIT_WIDTH_{port}\s*=\s*4\s*;", netlist):
                    raise ValueError(f"CPU DPB {name} is not 4096×4")
            data = 0
            for row, value in re.findall(r"defparam\s+" + re.escape(name)
                                        + r"\.INIT_RAM_([0-3][0-9A-Fa-f])\s*=\s*256'h([0-9A-Fa-f]+)\s*;", netlist):
                data |= int(value, 16) << (int(row, 16) * 256)
            if not data:
                raise ValueError(f"CPU DPB {name} has no identifiable initialized data")
            result[lane, bank] = data
    return result


def encode_block(data, logicinfo):
    # Each non-parity RAM block has 16384 bits. The device database supplies
    # the physical column of each bit plane; addresses select the fuse row.
    rows = [bytearray(b"0" * 180) for _ in range(256)]
    for address in range(16384):
        if not (data >> address) & 1:
            continue
        plane = address % 16
        if plane >= 8:
            plane += 1  # Skip the physical parity bit.
        column = logicinfo[plane * 4 + (address >> 12)][0] - 1
        quadrant = {0x00: 0, 0x10: 128, 0x20: 64, 0x30: 192}[address & 0x30]
        row = 255 - quadrant - ((address >> 6) & 63)
        rows[row][column] = ord("1")
    return [row.decode("ascii") for row in rows]


def block_locations(db):
    locations = []
    for row_index, row in enumerate(sorted(db.simplio_rows)):
        x = 0
        for col in range(db.cols):
            bels = db[row, col].bels
            if "BSRAM" in bels and "BSRAM_AUX" not in bels:
                locations.append((row_index * 256, x))
            x += db[0, col].width
    return locations


def locate_blocks(db, frames, old_bits):
    if len(frames) != db.height + 256 * len(db.simplio_rows):
        raise ValueError("Unexpected FS geometry or missing BSRAM initialization")
    padding = (-db.width) % 8
    if any(len(bits) != padding + db.width + 64 for _, bits in frames):
        raise ValueError("Unexpected FS frame width")
    ram = [bits[padding:-64][::-1] for _, bits in frames[db.height:]]
    locations = block_locations(db)
    selected = {}
    for key, data in old_bits.items():
        expected = encode_block(data, db.rev_logicinfo("BSRAM_INIT"))
        matches = [(y, x) for y, x in locations
                   if all(ram[y+i][x:x+180] == expected[i] for i in range(256))]
        if len(matches) != 1 or matches[0] in selected.values():
            raise ValueError(f"CPU RAM {key}: expected one unique content match, found {len(matches)}")
        selected[key] = matches[0]
    return ram, selected


def firmware_bits(binary):
    if not binary or len(binary) > 16384:
        raise ValueError("Firmware must contain 1–16384 bytes")
    binary = binary.ljust(16384, b"\0")
    result = {}
    for lane in range(4):
        for bank in range(2):
            data = 0
            for address in range(4096):
                nibble = (binary[address * 4 + lane] >> (bank * 4)) & 15
                data |= nibble << (address * 4)
            result[lane, bank] = data
    return result


def replace_frames(db, lines, frames, ram, selected, new_bits):
    changed = set()
    for key, (y, x) in selected.items():
        block = encode_block(new_bits[key], db.rev_logicinfo("BSRAM_INIT"))
        for offset in range(256):
            original = ram[y+offset]
            replacement = original[:x] + block[offset] + original[x+180:]
            if original != replacement:
                ram[y+offset] = replacement
                changed.add(y+offset)
    padding = (-db.width) % 8
    for index in sorted(changed):
        line_number, old = frames[db.height + index]
        payload = old[:padding] + ram[index][::-1]
        trailer = old[-48:]
        # RAM frames follow earlier frames, whose trailing six bytes seed CRC.
        previous = frames[db.height + index - 1][1][-48:]
        crc = crc16(int(previous, 2).to_bytes(6, "big")
                    + int(payload, 2).to_bytes(len(payload)//8, "big"))
        crc_bits = "".join(f"{byte:08b}" for byte in crc.to_bytes(2, "little"))
        lines[line_number] = payload + crc_bits + trailer
    output = "\n".join(lines) + "\n"
    read_frames(output)  # Validate every CRC before returning any result.
    return output, len(changed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base_fs", type=Path)
    parser.add_argument("netlist", type=Path)
    parser.add_argument("firmware_bin", type=Path)
    parser.add_argument("output_fs", type=Path)
    args = parser.parse_args()
    if args.output_fs.resolve() in {args.base_fs.resolve(), args.netlist.resolve(), args.firmware_bin.resolve()}:
        parser.error("output must not overwrite an input")
    try:
        from apycula.chipdb import load_chipdb
        db = load_chipdb(importlib.resources.files("apycula").joinpath("GW1N-9C.msgpack.xz"))
        lines, frames = read_frames(args.base_fs.read_text())
        old_bits = cpu_ram_bits(args.netlist.read_text())
        ram, selected = locate_blocks(db, frames, old_bits)
        output, count = replace_frames(db, lines, frames, ram, selected,
                                       firmware_bits(args.firmware_bin.read_bytes()))
        args.output_fs.write_text(output)
    except (OSError, ValueError, ImportError) as error:
        parser.exit(1, f"Gowin repack failed: {error}\n")
    print(f"Updated 8 CPU BSRAM blocks ({count} changed frames): {args.output_fs}")


if __name__ == "__main__":
    main()
