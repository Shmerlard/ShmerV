"""Test the patcher with synthetic text only; no FPGA commands/netlists."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/fpga/patch_gowin_memory_modes.py"
spec = importlib.util.spec_from_file_location("memory_patch", SCRIPT)
memory_patch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(memory_patch)


def fixture(cpu_mode="10", char_mode="10", char_count=4):
    lines = [
        f"defparam memory_lane{lane}_memory_lane{lane}_0_{bank}_s.WRITE_MODE0=2'b{cpu_mode};\n"
        for lane in range(4) for bank in range(2)
    ]
    lines += [
        f"defparam char_memory_char_memory_0_{bank}_s.WRITE_MODE0=2'b{char_mode};\n"
        for bank in range(char_count)
    ]
    return "".join(lines)


class MemoryPatchTest(unittest.TestCase):
    def run_patch(self, contents):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "synthetic.vg"
            path.write_text(contents)
            with patch("sys.argv", [str(SCRIPT), str(path)]):
                result = memory_patch.main()
            return result, path.read_text()

    def test_fresh_and_partial_and_repeated(self):
        for cpu_mode, char_mode in [("10", "10"), ("00", "10"), ("00", "00")]:
            with self.subTest(cpu_mode=cpu_mode, char_mode=char_mode):
                result, output = self.run_patch(fixture(cpu_mode, char_mode))
                self.assertEqual(result, 0)
                self.assertEqual(output, fixture("00", "00"))

    def test_old_cpu_only_and_legal_mode(self):
        result, output = self.run_patch(fixture(char_count=0))
        self.assertEqual(result, 0)
        self.assertEqual(output, fixture("00", char_count=0))
        result, output = self.run_patch(fixture("01", "10"))
        self.assertEqual(result, 0)
        self.assertEqual(output, fixture("01", "00"))

    def test_unexpected_count_or_mode_unchanged(self):
        for contents in [fixture(char_count=3), fixture(char_mode="11")]:
            result, output = self.run_patch(contents)
            self.assertEqual(result, 1)
            self.assertEqual(output, contents)


if __name__ == "__main__":
    unittest.main()
