"""Synthetic FS tests only. Never generate/repack an actual FPGA design."""
import importlib.util
from pathlib import Path
import random
from types import SimpleNamespace
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/fpga/repack_gowin_fs.py"
spec = importlib.util.spec_from_file_location("gowin_repack", SCRIPT)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class FakeDatabase:
    width, height, cols = 1620, 2, 27
    simplio_rows = {0}

    def __getitem__(self, key):
        return SimpleNamespace(width=60, bels={"BSRAM": object()} if key[1] % 3 == 0 else {})

    def rev_logicinfo(self, name):
        return {index: (index+1,) for index in range(72)}


def fixture():
    db = FakeDatabase()
    rng = random.Random(42)
    old = m.firmware_bits(rng.randbytes(1024))
    ram = ["0" * db.width for _ in range(256)]
    for index, (_, data) in enumerate(old.items()):
        block = m.encode_block(data, db.rev_logicinfo("BSRAM_INIT"))
        for row in range(256):
            start = index * 180
            ram[row] = ram[row][:start] + block[row] + ram[row][start+180:]
    for row in range(256):
        ram[row] = ram[row][:-180] + ("10" * 90)  # Unrelated font memory.
    metadata = ["//Device: GW1NR-9", "//Device Version: C", "//Compress: OFF",
                "//Encryption: OFF", "//CRCCheck: ON"]
    commands = ["1"*160, "1"*16, f"{0xA5C3:016b}",
                f"{0x060000001100481B:064b}", f"{0x3B800102:032b}"]
    seed = bytes.fromhex("060000001100481b3b800102")
    frames = []
    for row in ["01" * (db.width//2)]*db.height + ram:
        payload = "1111" + row[::-1]
        checksum = m.crc16(seed + int(payload, 2).to_bytes(len(payload)//8, "big"))
        frames.append(payload + "".join(f"{b:08b}" for b in checksum.to_bytes(2, "little")) + "1"*48)
        seed = b"\xff"*6
    text = "\n".join(metadata + commands + frames + ["1"*160, f"{0x08000000:032b}"]) + "\n"
    return db, old, text


class RepackTest(unittest.TestCase):
    def test_crc_known_vector(self):
        self.assertEqual(m.crc16(b"123456789"), 0xBB3D)

    def test_roundtrip_and_preservation(self):
        db, old, text = fixture()
        lines, frames = m.read_frames(text)
        ram, locations = m.locate_blocks(db, frames, old)
        original_ram = ram.copy()
        new = m.firmware_bits(random.Random(99).randbytes(512))
        output, count = m.replace_frames(db, lines, frames, ram, locations, new)
        self.assertGreater(count, 0)
        out_lines, out_frames = m.read_frames(output)
        _, new_locations = m.locate_blocks(db, out_frames, new)
        self.assertEqual(locations, new_locations)
        self.assertEqual(frames[:db.height], out_frames[:db.height])
        for row in range(256):
            self.assertEqual(ram[row][-180:], original_ram[row][-180:])
        frame_lines = {number for number, _ in frames[db.height:]}
        for number, line in enumerate(text.splitlines()):
            if number not in frame_lines:
                self.assertEqual(out_lines[number], line)

    def test_noop(self):
        db, old, text = fixture()
        lines, frames = m.read_frames(text)
        ram, locations = m.locate_blocks(db, frames, old)
        output, count = m.replace_frames(db, lines, frames, ram, locations, old)
        self.assertEqual(count, 0)
        self.assertEqual(output, text)

    def test_reject_corrupt_unsupported_or_oversized(self):
        db, old, text = fixture()
        with self.assertRaises(ValueError):
            m.read_frames(text.replace("//Compress: OFF", "//Compress: ON"))
        lines, frames = m.read_frames(text)
        number, bits = frames[0]
        lines[number] = ("0" if bits[0] == "1" else "1") + bits[1:]
        with self.assertRaises(ValueError):
            m.read_frames("\n".join(lines))
        with self.assertRaises(ValueError):
            m.firmware_bits(b"X" * 16385)
        with self.assertRaises(ValueError):
            m.locate_blocks(db, frames, {(0, 0): 1})


if __name__ == "__main__":
    unittest.main()
