#!/usr/bin/env python3

import json
import sys
from pathlib import Path


def usage() -> None:
    print(
        "Usage: patch_bram_init.py FRESH_NETLIST ROUTED_NETLIST OUTPUT_NETLIST",
        file=sys.stderr,
    )


def bram_cells(design: dict) -> dict[str, dict]:
    cells: dict[str, dict] = {}
    for module in design["modules"].values():
        for name, cell in module.get("cells", {}).items():
            parameters = cell.get("parameters", {})
            if "INIT_RAM_00" in parameters:
                if name in cells:
                    raise ValueError(f"duplicate initialized BRAM cell: {name}")
                cells[name] = cell
    return cells


def init_parameters(cell: dict) -> dict[str, str]:
    return {
        name: value
        for name, value in cell["parameters"].items()
        if name.startswith("INIT_RAM_")
    }


def main() -> int:
    if len(sys.argv) != 4:
        usage()
        return 1

    fresh_path, routed_path, output_path = map(Path, sys.argv[1:])
    fresh = json.loads(fresh_path.read_text())
    routed = json.loads(routed_path.read_text())

    fresh_cells = bram_cells(fresh)
    routed_cells = bram_cells(routed)

    if not fresh_cells:
        raise ValueError("fresh netlist has no initialized BRAM cells")
    if fresh_cells.keys() != routed_cells.keys():
        missing = sorted(fresh_cells.keys() - routed_cells.keys())
        extra = sorted(routed_cells.keys() - fresh_cells.keys())
        raise ValueError(
            f"BRAM cell mismatch; missing in routed={missing}, extra in routed={extra}"
        )

    for name, fresh_cell in fresh_cells.items():
        fresh_init = init_parameters(fresh_cell)
        routed_init = init_parameters(routed_cells[name])
        if fresh_init.keys() != routed_init.keys():
            raise ValueError(f"BRAM initialization fields differ for {name}")
        routed_cells[name]["parameters"].update(fresh_init)

    output_path.write_text(json.dumps(routed, separators=(",", ":")))
    print(f"Patched {len(fresh_cells)} BRAM cells")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyError, ValueError, json.JSONDecodeError) as error:
        print(f"BRAM patch failed: {error}", file=sys.stderr)
        raise SystemExit(1)
