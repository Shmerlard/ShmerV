build_dir := "build"
sv_sources := "rtl/smoke.sv tb/smoke_tb.sv"

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

test:
  mkdir -p {{build_dir}}
  verilator --binary --timing --trace-fst --top-module smoke_tb \
    --Mdir {{build_dir}}/obj_smoke -o smoke_test {{sv_sources}}
  ./{{build_dir}}/obj_smoke/smoke_test

clean:
  rm -rf {{build_dir}}
