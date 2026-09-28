#!/usr/bin/env python3

from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys


SPIKE_BASE = 0x80000000
SPIKE_MEMORY_SIZE = 0x8000
REGISTER_NAMES = (
    "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
)


@dataclass(frozen=True)
class Check:
    kind: str
    location: int


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=True, capture_output=True, text=True)


def parse_checks(path: Path) -> list[Check]:
    checks = []

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        fields = line.partition("#")[0].split()
        if not fields:
            continue
        if len(fields) != 2 or fields[0] not in ("memory", "register"):
            raise ValueError(f"{path}:{line_number}: invalid check entry")

        location_base = 10 if fields[0] == "register" else 16
        location = int(fields[1], location_base)
        if fields[0] == "register" and not 0 <= location < len(REGISTER_NAMES):
            raise ValueError(f"{path}:{line_number}: invalid register x{location}")
        if fields[0] == "memory" and not SPIKE_BASE <= location < SPIKE_BASE + SPIKE_MEMORY_SIZE:
            raise ValueError(f"{path}:{line_number}: memory address is outside the test memory")
        if fields[0] == "memory" and location % 4 != 0:
            raise ValueError(f"{path}:{line_number}: memory address is not word-aligned")
        checks.append(Check(fields[0], location))

    if not checks:
        raise ValueError(f"{path}: no checks defined")
    return checks


def find_test_end(elf_file: Path) -> int:
    symbols = run_command(["riscv32-none-elf-nm", str(elf_file)]).stdout
    for line in symbols.splitlines():
        fields = line.split()
        if len(fields) == 3 and fields[2] == "_test_end":
            return int(fields[0], 16)
    raise ValueError(f"Missing _test_end symbol in {elf_file}")


def create_debug_commands(checks: list[Check], end_address: int) -> str:
    commands = [f"until pc 0 {end_address:x}"]

    for check in checks:
        if check.kind == "memory":
            commands.append(f"mem {check.location:x}")
        else:
            commands.append(f"reg 0 {REGISTER_NAMES[check.location]}")

    commands.append("quit")
    return "\n".join(commands) + "\n"


def run_spike(elf_file: Path, command_file: Path) -> list[int]:
    result = run_command([
        "spike",
        "-d",
        f"--debug-cmd={command_file}",
        "--isa=rv32i",
        f"-m{SPIKE_BASE:#x}:{SPIKE_MEMORY_SIZE:#x}",
        str(elf_file),
    ])
    output = result.stdout + result.stderr
    return [int(line, 16) for line in output.splitlines() if line.startswith("0x")]


def write_expected(path: Path, checks: list[Check], values: list[int]) -> None:
    if len(values) != len(checks):
        raise ValueError(f"Spike returned {len(values)} results for {len(checks)} checks")

    lines = []
    for check, value in zip(checks, values):
        location = str(check.location) if check.kind == "register" else f"{check.location:08x}"
        lines.append(f"{check.kind} {location} {value & 0xFFFFFFFF:08x}")
    path.write_text("\n".join(lines) + "\n")


def main() -> None:
    if len(sys.argv) != 4:
        raise ValueError(f"Usage: {sys.argv[0]} CHECKS_FILE ELF_FILE EXPECTED_FILE")

    checks_file = Path(sys.argv[1])
    elf_file = Path(sys.argv[2])
    expected_file = Path(sys.argv[3])
    checks = parse_checks(checks_file)
    command_file = expected_file.parent / "spike-debug.cmd"
    command_file.write_text(create_debug_commands(checks, find_test_end(elf_file)))
    write_expected(expected_file, checks, run_spike(elf_file, command_file))


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        print(error.stderr or error.stdout or error, file=sys.stderr)
        sys.exit(1)
    except (FileNotFoundError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
