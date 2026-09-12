#!/bin/sh
set -eu

module=${1:-}
program=${2:-}
build_directory=build

build_test() {
  test_module=$1
  rtl_source=$(find rtl -type f -name "$test_module.sv" -print -quit)
  testbench=$(find tb -type f -name "${test_module}_tb.sv" -print -quit)

  if [ -z "$rtl_source" ] || [ -z "$testbench" ]; then
    echo "Missing RTL or testbench for $test_module" >&2
    exit 1
  fi

  mkdir -p "$build_directory"
  package_sources=$(find rtl -type f -name '*_types.sv' | sort)
  rtl_sources=$(find rtl -type f -name '*.sv' ! -name '*_types.sv' | sort)

  verilator --binary --timing --trace-fst \
    --top-module "${test_module}_tb" \
    --trace-max-array 1025 --trace-max-width 0 \
    --Mdir "$build_directory/obj_$test_module" -o "${test_module}_test" \
    $package_sources $rtl_sources "$testbench"
}

run_cpu_system_program() {
  program_name=$1
  program_source="sw/tests/cpu_system/$program_name.S"
  expected_file="sw/tests/cpu_system/$program_name.expected"
  program_build_directory="$build_directory/cpu_system/$program_name"

  if [ ! -f "$program_source" ] || [ ! -f "$expected_file" ]; then
    echo "Missing $program_source or $expected_file" >&2
    exit 1
  fi

  read -r cycles expected_address expected_value < "$expected_file"
  scripts/build_cpu_system_program.sh "$program_source" "$program_build_directory"

  echo "Running CPU-system program: $program_name"
  "$build_directory/obj_cpu_system/cpu_system_test" \
    "+memory_init=$program_build_directory/program.hex" \
    "+cycles=$cycles" \
    "+expected_address=$expected_address" \
    "+expected_value=$expected_value" \
    "+trace_file=$program_build_directory/waveform.fst"
}

run_cpu_system_tests() {
  selected_program=$1
  build_test cpu_system

  if [ -n "$selected_program" ]; then
    run_cpu_system_program "$selected_program"
    return
  fi

  found_program=0
  for program_source in sw/tests/cpu_system/*.S; do
    if [ ! -f "$program_source" ]; then
      continue
    fi
    found_program=1
    program_name=$(basename "$program_source" .S)
    run_cpu_system_program "$program_name"
  done

  if [ "$found_program" -eq 0 ]; then
    echo "No CPU-system programs found" >&2
    exit 1
  fi
}

if [ -z "$module" ]; then
  for testbench in $(find tb -type f -name '*_tb.sv' | sort); do
    test_module=$(basename "$testbench" _tb.sv)
    if [ "$test_module" = "cpu_system" ]; then
      run_cpu_system_tests ""
    else
      build_test "$test_module"
      "$build_directory/obj_$test_module/${test_module}_test"
    fi
  done
elif [ "$module" = "cpu_system" ]; then
  run_cpu_system_tests "$program"
elif [ -n "$program" ]; then
  echo "A program name is only valid with: just test cpu_system PROGRAM" >&2
  exit 1
else
  build_test "$module"
  "$build_directory/obj_$module/${module}_test"
fi
