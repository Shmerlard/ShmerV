# Project Structure

The repository separates reusable RTL, board-specific FPGA targets, runnable
software, verification-only programs, and workflow scripts.

```text
rtl/core/                    Reusable CPU and its pipeline internals
rtl/soc/                     Memory, address decoding, and CPU-system integration
rtl/peripherals/             GPIO and peripheral management
rtl/types/                   Shared SystemVerilog packages
fpga/tang_nano_9k/           Tang Nano 9K targets
  gpio_bringup/              Direct GPIO hardware test
  cpu_system/                Complete SoC target for selected programs
  cpu_synthesis/             Temporary placement/timing probe
sw/runtime/                  Shared bare-metal startup
sw/linker/                   Simulation and FPGA memory layouts
sw/programs/                 Programs intended to run on the FPGA system
tb/unit/                     Module-level SystemVerilog tests
tb/cpu/                      Complete CPU/system testbenches
tb/cpu/programs/             Test-only software and Spike check descriptions
tb/support/                  Shared test-build support files
tb/waves/                    Persistent Surfer layouts
scripts/software/            Software compilation
scripts/test/                Regression and Spike-reference generation
scripts/simulation/          Traced simulation and viewers
scripts/fpga/                FPGA listing, synthesis, build, and programming
planning/                    Detailed local architecture and roadmap notes
build/                       Generated artifacts; never committed
```

## FPGA Targets and Programs

An FPGA target describes hardware; a software program describes code executed
by that hardware. They are selected independently. The complete Tang Nano 9K
target can therefore run `gpio_pattern` now and later run other programs without
creating another top-level SystemVerilog module.

Each buildable target contains its top-level SystemVerilog file, pin constraints,
and `sources.f` source list. The board-level README lists the available targets.

```sh
just fpga-list targets
just fpga-list programs
just fpga-list images
just fpga-build cpu_system gpio_pattern
just fpga-flash cpu_system gpio_pattern
```

Firmware is currently embedded into block-RAM initialization, so selecting a
different program rebuilds the FPGA image. A UART firmware loader is planned as
a later feature.

## Verification Software

Programs under `tb/cpu/programs/` exist only to verify the CPU. Their `.checks`
files select architectural state that Spike evaluates before Verilator compares
the RTL result. Runnable demonstration firmware belongs under `sw/programs/`
instead.
