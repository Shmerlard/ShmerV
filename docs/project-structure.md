# Project Structure

The repository separates reusable RTL, board-specific FPGA targets, runnable
software, verification-only programs, and workflow scripts.

The IF-stage diagram under `docs/diagrams/` is an early sketch. It omits the
current redirect and stall control and uses older signal names; use the RTL
for the current interface.

```text
rtl/core/                    Reusable CPU and its pipeline internals
rtl/soc/                     Memory, address decoding, and CPU-system integration
rtl/peripherals/             GPIO, UART TX, and peripheral management
rtl/types/                   Shared SystemVerilog packages
fpga/gowin/                  Primitive declaration stubs for code diagnostics
fpga/tang_nano_9k/           Tang Nano 9K targets
  gpio_bringup/              Direct GPIO hardware test
  soc/                Complete SoC target for selected programs
sw/runtime/                  Shared bare-metal startup
sw/linker/                   Simulation and FPGA memory layouts
sw/include/                  MMIO definitions and C interrupt declarations
sw/programs/                 Programs intended to run on the FPGA system
tb/unit/                     Module-level SystemVerilog tests
tb/core/                      Complete CPU/system testbenches
tb/fpga/                     Board-wrapper simulation tests
tb/core/programs/             Test-only software and Spike check descriptions
tb/support/                  Shared test-build support files
tb/waves/                    Persistent Surfer layouts
scripts/software/            Software compilation
scripts/test/                Regression and Spike-reference generation
scripts/simulation/          Traced simulation and viewers
scripts/fpga/                FPGA listing, synthesis, build, and programming
build/                       Generated artifacts; never committed
```

## FPGA Targets and Programs

The fixed SoC peripheral map is defined in `rtl/types/soc_address_map.sv`.
Peripheral type packages define local register indices; byte offsets are those
indices multiplied by four. Firmware uses `sw/include/shmerv_memory_map.h`.

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
just fpga-build soc gpio_pattern
just fpga-flash soc gpio_pattern
```

Firmware is embedded into block-RAM initialization. `just fpga-repack` can
replace it while reusing an existing placement and routing result, provided
the hardware is unchanged. The default backend uses nextpnr's routed JSON;
`just fpga-repack soc PROGRAM --gowin` instead updates CPU RAM data
in the existing Gowin FS, preserving logic/routing and other memory contents.
A UART firmware loader is not implemented yet.

## Verification Software

Programs under `tb/core/programs/` exist only to verify the CPU. Their `.checks`
files select architectural state that Spike evaluates before Verilator compares
the RTL result. SoC-specific tests whose GPIO/custom interrupts are unavailable
in Spike instead provide hand-written `.expected` files. Runnable demonstration
firmware belongs under `sw/programs/` instead.

Hand-written `.expected` files also support final CSR checks such as
`csr mcause 00000006` and `csr mtval 80001003`. Supported names are `mstatus`,
`mtvec`, `mepc`, `mcause`, and `mtval`; `mval` is accepted as an alias for
`mtval`. Values are hexadecimal. CSR entries are not supported in Spike `.checks`
files.
