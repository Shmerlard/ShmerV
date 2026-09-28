build_dir := "build"
sv_sources := `find rtl tb -type f -name '*.sv' | sort | tr '\n' ' '`
verilator_sources := `find rtl tb -type f -name '*.sv' ! -path 'rtl/types/*_types.sv' | sort | tr '\n' ' '`

# Show the command list when Just is run without arguments.
default:
  @just help

# Show one-line descriptions of every command.
help:
  @just --list

# Format every SystemVerilog source file.
format:
  verible-verilog-format --inplace {{sv_sources}}

# Check SystemVerilog formatting without changing files.
format-check:
  @for file in {{sv_sources}}; do \
    verible-verilog-format --verify "$file" || exit 1; \
  done

# Run Verible and Verilator lint checks.
lint:
  verible-verilog-lint {{sv_sources}}
  verilator --lint-only --timing --top-module cpu_system rtl/types/csr_types.sv rtl/types/core_types.sv {{verilator_sources}}

# Run tests, one CPU program, or list CPU programs with: just test cpu_system -l.
test module="" program="":
  @scripts/test/run_tests.sh "{{module}}" "{{program}}"

# Run one test with tracing enabled, then open its waveform in Surfer.
# Add --elf for a CPU-system program to open its disassembly in another window.
sim module program="" display="":
  @scripts/simulation/run_sim.sh "{{module}}" "{{program}}" "{{display}}"

# Open an existing waveform without rerunning the test.
wave module program="":
  @scripts/simulation/open_wave.sh "{{module}}" "{{program}}"

# Build a standalone peripheral target for the Tang Nano 9K.
fpga-build design:
  @scripts/build_standalone_fpga.sh "{{design}}"

# Load a standalone target into SRAM, or pass "flash" for persistent storage.
fpga-flash design mode="sram":
  @scripts/flash_standalone_fpga.sh "{{design}}" "{{mode}}"

# Remove all generated build files.
clean:
  rm -rf {{build_dir}}
