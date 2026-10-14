#!/usr/bin/env python3

import re
import sys
from pathlib import Path


PATTERN = re.compile(
    r"(defparam\s+(?P<name>memory_lane[0-3]_memory_lane[0-3]_\S+"
    r"|char_memory_char_memory_\S+)\.WRITE_MODE0\s*=\s*)"
    r"2'b(?P<mode>[01]{2});"
)


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: patch_gowin_memory_modes.py NETLIST", file=sys.stderr)
        return 1

    netlist_path = Path(sys.argv[1])
    netlist = netlist_path.read_text()
    matches = list(PATTERN.finditer(netlist))
    cpu_count = sum(match["name"].startswith("memory_lane") for match in matches)
    char_count = len(matches) - cpu_count
    if cpu_count != 8 or char_count not in (0, 4):
        print(
            f"Expected 8 CPU DPBs and 0 or 4 character DPBs; "
            f"found {cpu_count} CPU and {char_count} character DPBs; "
            "netlist was not changed",
            file=sys.stderr,
        )
        return 1

    if any(match["mode"] not in ("00", "01", "10") for match in matches):
        print("Unexpected memory write mode; netlist was not changed", file=sys.stderr)
        return 1

    count = 0

    def patch_mode(match: re.Match) -> str:
        nonlocal count
        if match["mode"] != "10":
            return match[0]
        count += 1
        return match[1] + "2'b00;"

    patched = PATTERN.sub(patch_mode, netlist)
    if count:
        netlist_path.write_text(patched)
    print(f"Patched {count} memory DPBs from WRITE_MODE0=10 to 00")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
