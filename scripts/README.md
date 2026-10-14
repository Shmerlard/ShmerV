# Scripts

Scripts are grouped by the workflow that owns them. The `justfile` is the normal user-facing interface.

Common FPGA commands are:

```sh
just fpga-list targets
just fpga-list programs
just fpga-list images
just fpga-build soc gpio_pattern
just fpga-flash soc gpio_pattern
just fpga-flash soc gpio_pattern flash
```

## `completion/`

- `just.zsh` completes recipes, test modules, CPU programs, FPGA targets,
  firmware programs, and programming modes without running FPGA commands.

`nix develop` opens a project zsh shell with completion enabled automatically.
Direnv alone loads environment variables, not completion functions. To load
completion manually in an existing shell:

```zsh
source /home/elad/Projects/ShmerV/scripts/completion/just.zsh
```

## `software/`

- `build_program.sh` compiles or assembles one bare-metal program and produces ELF, binary, and hexadecimal memory images.

## `test/`

- `run_tests.sh` builds and runs unit tests and CPU-system program tests.
- `generate_expected.py` runs Spike and creates expected register or memory values from a test's `.checks` file.
- UART stream simulation and hardware testing live together in
  [`tb/integration/uart_stream/`](../tb/integration/uart_stream/README.md).

## `simulation/`

- `run_sim.sh` runs a traced test and opens its waveform.
- `open_wave.sh` opens an existing waveform in Surfer.
- `open_elf.sh` opens an ELF disassembly in a terminal.

## `fpga/`

- `list.sh` lists FPGA targets, software programs, and already-built bitstreams.
- `build_target.sh` builds a Tang Nano 9K target and embeds a selected program when required.
- `flash_target.sh` loads a built image into FPGA SRAM or persistent flash.
- `repack_program.sh` replaces firmware while keeping the existing routed
  hardware; optional `--gowin` selects the IDE FS instead of nextpnr JSON.
- `repack_gowin_fs.py` validates an uncompressed GW1NR-9C FS, identifies the
  eight CPU RAM blocks from the matching synthesis netlist, replaces their
  initialization, and updates frame CRCs without changing other memories.
- `synthesize_core.sh` reports generic CPU synthesis results.
- `synthesize_core_gowin.sh` maps the CPU to Gowin primitives.
