build_dir := "build"
sv_sources := `find rtl tb -type f -name '*.sv' | sort | tr '\n' ' '`

default:
  @just --list

format:
  verible-verilog-format --inplace {{sv_sources}}

format-check:
  @for file in {{sv_sources}}; do \
    verible-verilog-format --verify "$file" || exit 1; \
  done

lint:
  verible-verilog-lint {{sv_sources}}
  verilator --lint-only --timing --top-module smoke_tb {{sv_sources}}

# Run all tests, one module test, all CPU-system programs, or one named program.
test module="" program="":
  @scripts/run_tests.sh "{{module}}" "{{program}}"

# Verify CPU-system expectations against the Spike reference simulator.
reference program="":
  @python3 scripts/run_spike_reference.py "{{program}}"

# Verify CPU-system expectations with both RTL simulation and Spike.
verify program="":
  @just reference "{{program}}"
  @just test cpu_system "{{program}}"

clean:
  rm -rf {{build_dir}}
