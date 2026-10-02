# Scripts

Scripts are grouped by the workflow that owns them. The `justfile` is the normal user-facing interface.

Common FPGA commands are:

```sh
just fpga-list targets
just fpga-list programs
just fpga-list images
just fpga-build cpu_system gpio_pattern
just fpga-flash cpu_system gpio_pattern
just fpga-flash cpu_system gpio_pattern flash
```

## `software/`

- `build_program.sh` compiles or assembles one bare-metal program and produces ELF, binary, and hexadecimal memory images.

## `test/`

- `run_tests.sh` builds and runs unit tests and CPU-system program tests.
- `generate_expected.py` runs Spike and creates expected register or memory values from a test's `.checks` file.

## `simulation/`

- `run_sim.sh` runs a traced test and opens its waveform.
- `open_wave.sh` opens an existing waveform in Surfer.
- `open_elf.sh` opens an ELF disassembly in a terminal.

## `fpga/`

- `list.sh` lists FPGA targets, software programs, and already-built bitstreams.
- `build_target.sh` builds a Tang Nano 9K target and embeds a selected program when required.
- `flash_target.sh` loads a built image into FPGA SRAM or persistent flash.
- `synthesize_cpu.sh` reports generic CPU synthesis results.
- `synthesize_cpu_gowin.sh` maps the CPU to Gowin primitives.
