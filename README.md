# ShmerV

ShmerV is a learning-focused RV32I five-stage pipelined CPU written in SystemVerilog. The current repository contains the CPU RTL, module testbenches, and small assembly programs that test the complete CPU and memory system.

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
just wave alu                     # Reopen an existing waveform
just wave cpu_system basic        # Reopen a CPU waveform
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
- `sw/tests/cpu_system/<program>/` contains assembly or C programs and human-written `.checks` files.
- `build/` contains generated programs, logs, test executables, expected values, and waveforms.
