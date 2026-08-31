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

test module="":
  @set -e; \
  if [ -n "{{module}}" ]; then \
    rtl_source=$(find rtl -type f -name '{{module}}.sv' -print -quit); \
    testbench=$(find tb -type f -name '{{module}}_tb.sv' -print -quit); \
    if [ -z "$rtl_source" ] || [ -z "$testbench" ]; then \
      echo "Missing RTL or testbench for {{module}}"; \
      exit 1; \
    fi; \
    mkdir -p {{build_dir}}; \
    package_sources=$(find rtl -type f -name '*_types.sv' | sort); \
    rtl_sources=$(find rtl -type f -name '*.sv' ! -name '*_types.sv' | sort); \
    verilator --binary --timing --trace-fst --top-module {{module}}_tb \
      --Mdir {{build_dir}}/obj_{{module}} -o {{module}}_test \
      $package_sources $rtl_sources "$testbench"; \
    ./{{build_dir}}/obj_{{module}}/{{module}}_test; \
  else \
    for testbench in $(find tb -type f -name '*_tb.sv' | sort); do \
      test_name=$(basename "$testbench" _tb.sv); \
      just test "$test_name"; \
    done; \
  fi

clean:
  rm -rf {{build_dir}}
