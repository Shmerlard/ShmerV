# ShmerV

ShmerV is a learning-focused RV32I five-stage pipelined CPU and small SoC written in SystemVerilog. It currently runs compiled C firmware on a Tang Nano 9K and drives physical LEDs through an MMIO GPIO peripheral.

## Quick Start

Enter the reproducible development environment:

```sh
nix develop
```

Common commands:

```sh
just help                         # List available commands
just test                         # Run every test
just test alu                     # Run one module test
just test cpu_system basic        # Run one CPU software test
just test cpu_system -l           # List CPU software tests
just sim alu                      # Run with tracing and open Surfer
just sim cpu_system basic         # Trace one CPU software test
just sim cpu_system basic --elf   # Also open the ELF disassembly
just wave alu                     # Reopen an existing waveform
just wave cpu_system basic        # Reopen a CPU waveform
just fpga-list                    # List FPGA targets, programs, and built images
just fpga-build cpu_system gpio_pattern
just fpga-flash cpu_system gpio_pattern
just clean                        # Remove generated build files
```

Maintenance commands:

```sh
just format
just format-check
just lint
```

## Testing Layout

- `rtl/` contains the hardware.
- `tb/` contains SystemVerilog testbenches and persistent Surfer layouts.
- `tb/cpu/programs/<program>/` contains test-only assembly or C programs and human-written `.checks` files.
- `sw/programs/` contains bare-metal programs intended to run on the FPGA system.
- `build/` contains generated programs, logs, test executables, expected values, and waveforms.

See [Project structure](docs/project-structure.md) for directory ownership and
the FPGA/software relationship.
