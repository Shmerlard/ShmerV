#!/usr/bin/env python3

import re
import sys
from pathlib import Path


EXPECTED_DPBS = 8
PATTERN = re.compile(
    r"(defparam memory_lane[0-3]_memory_lane[0-3]_\S+\.WRITE_MODE0=)2'b10;"
)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: patch_gowin_memory_modes.py NETLIST", file=sys.stderr)
        return 1

    netlist_path = Path(sys.argv[1])
    netlist = netlist_path.read_text()
    patched, count = PATTERN.subn(r"\g<1>2'b00;", netlist)

    if count != EXPECTED_DPBS:
        print(
            f"Expected {EXPECTED_DPBS} illegal memory DPB modes, found {count}; "
            "netlist was not changed",
            file=sys.stderr,
        )
        return 1

    netlist_path.write_text(patched)
    print(f"Patched {count} memory DPBs from WRITE_MODE0=10 to 00")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
