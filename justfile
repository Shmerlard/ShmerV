build_dir := "build"
sv_sources := `find rtl tb -type f -name '*.sv' | sort | tr '\n' ' '`

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
  verilator --lint-only --timing --top-module smoke_tb {{sv_sources}}

# Run tests, one CPU program, or list CPU programs with: just test cpu_system -l.
test module="" program="":
  @scripts/run_tests.sh "{{module}}" "{{program}}"

# Run one test with tracing enabled, then open its waveform in Surfer.
sim module program="":
  @scripts/run_sim.sh "{{module}}" "{{program}}"

# Open an existing waveform without rerunning the test.
wave module program="":
  @scripts/open_wave.sh "{{module}}" "{{program}}"

# Remove all generated build files.
clean:
  rm -rf {{build_dir}}
