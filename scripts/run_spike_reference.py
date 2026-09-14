#!/usr/bin/env python3

from dataclasses import dataclass
from pathlib import Path
import subprocess
import sys


TEST_DIRECTORY = Path("sw/tests/cpu_system")
BUILD_DIRECTORY = Path("build/spike")
SPIKE_BASE = 0x80000000
SPIKE_MEMORY_SIZE = 0x1000
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
    expected_value: int


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=True, capture_output=True, text=True)


def parse_expected(path: Path) -> list[Check]:
    checks = []

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        fields = line.split()
        if not fields or fields[0] == "cycles":
            continue
        if len(fields) != 3 or fields[0] not in ("memory", "register"):
            raise ValueError(f"{path}:{line_number}: invalid expected entry")

        location_base = 10 if fields[0] == "register" else 16
        checks.append(Check(fields[0], int(fields[1], location_base), int(fields[2], 16)))

    return checks


def build_program(program: str, build_directory: Path) -> Path:
    source = TEST_DIRECTORY / f"{program}.S"
    object_file = build_directory / "program.o"
    elf_file = build_directory / "program.elf"

    run_command([
        "riscv32-none-elf-as",
        "-march=rv32i",
        "-mabi=ilp32",
        "--defsym",
        "SPIKE_REFERENCE=1",
        "-o",
        str(object_file),
        str(source),
    ])
    run_command([
        "riscv32-none-elf-ld",
        "-m",
        "elf32lriscv",
        "-T",
        str(TEST_DIRECTORY / "spike.ld"),
        "-o",
        str(elf_file),
        str(object_file),
    ])

    return elf_file


def find_test_end(elf_file: Path) -> int:
    symbols = run_command(["riscv32-none-elf-nm", str(elf_file)]).stdout
    for line in symbols.splitlines():
        address, _, name = line.split()
        if name == "_test_end":
            return int(address, 16)
    raise ValueError(f"Missing _test_end symbol in {elf_file}")


def create_debug_commands(checks: list[Check], end_address: int) -> str:
    commands = [f"until pc 0 {end_address:x}"]

    for check in checks:
        if check.kind == "memory":
            commands.append(f"mem {SPIKE_BASE + check.location:x}")
        else:
            if check.location >= len(REGISTER_NAMES):
                raise ValueError(f"Invalid register index: {check.location}")
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


def compare_results(program: str, checks: list[Check], actual_values: list[int]) -> None:
    if len(actual_values) != len(checks):
        raise ValueError(f"Spike returned {len(actual_values)} results for {len(checks)} checks")

    for check, actual in zip(checks, actual_values):
        normalized_actual = actual - SPIKE_BASE if actual >= SPIKE_BASE else actual
        if actual != check.expected_value and normalized_actual != check.expected_value:
            raise ValueError(
                f"expected {check.kind} {check.location:x} = {check.expected_value:08x}, "
                f"got {actual:08x}"
            )

    print(f"[PASS]  spike/{program}")


def run_program(program: str) -> None:
    source = TEST_DIRECTORY / f"{program}.S"
    expected_file = TEST_DIRECTORY / f"{program}.expected"
    if not source.exists() or not expected_file.exists():
        raise FileNotFoundError(f"Missing {source} or {expected_file}")

    program_build_directory = BUILD_DIRECTORY / program
    program_build_directory.mkdir(parents=True, exist_ok=True)

    checks = parse_expected(expected_file)
    elf_file = build_program(program, program_build_directory)
    command_file = program_build_directory / "debug.cmd"
    command_file.write_text(create_debug_commands(checks, find_test_end(elf_file)))
    actual_values = run_spike(elf_file, command_file)
    compare_results(program, checks, actual_values)


def main() -> None:
    selected_program = sys.argv[1] if len(sys.argv) == 2 else ""
    programs = (
        [selected_program]
        if selected_program
        else [path.stem for path in TEST_DIRECTORY.glob("*.S")]
    )
    for program in sorted(programs):
        run_program(program)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError, subprocess.CalledProcessError) as error:
        print(f"[FAIL]  {error}", file=sys.stderr)
        sys.exit(1)
