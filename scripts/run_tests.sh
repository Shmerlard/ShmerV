#!/bin/sh
set -eu

module=${1:-}
program=${2:-}
build_mode=${3:-test}
build_directory=build
test_jobs=${TEST_JOBS:-4}

if [ "$build_mode" != "test" ] && [ "$build_mode" != "trace" ]; then
  echo "Unknown test build mode: $build_mode" >&2
  exit 1
fi

report_module_pass() {
  test_module=$1

  if [ -z "${TEST_TOTAL:-}" ]; then
    echo "[PASS]  $test_module"
    return
  fi

  completed=$(flock "$TEST_PROGRESS_FILE.lock" sh -c '
    completed=$(cat "$1")
    completed=$((completed + 1))
    printf "%s\n" "$completed" > "$1"
    printf "%s" "$completed"
  ' sh "$TEST_PROGRESS_FILE")
  echo "[PASS]  $test_module ($completed/$TEST_TOTAL modules)"
}

build_test() {
  test_module=$1
  test_build_directory="$build_directory/tests/$test_module/$build_mode"
  rtl_source=$(find rtl -type f -name "$test_module.sv" -print -quit)
  testbench=$(find tb -type f -name "${test_module}_tb.sv" -print -quit)

  if [ -z "$rtl_source" ] || [ -z "$testbench" ]; then
    echo "Missing RTL or testbench for $test_module" >&2
    exit 1
  fi

  mkdir -p "$test_build_directory"
  package_sources=$(find rtl -type f -name '*_types.sv' | sort)
  rtl_library_arguments="+libext+.sv"
  for rtl_directory in $(find rtl -type d | sort); do
    rtl_library_arguments="$rtl_library_arguments -y $rtl_directory"
  done
  trace_arguments=
  if [ "$build_mode" = "trace" ]; then
    trace_arguments="--trace-fst --trace-max-array 1025 --trace-max-width 0"
  fi

  echo "[BUILD] $test_module ($build_mode)"
  if ! verilator --binary --timing --timescale-override 1ns/1ns $trace_arguments \
    --top-module "${test_module}_tb" \
    --Mdir "$test_build_directory/obj" -o "${test_module}_test" \
    $package_sources tb/core_types_import.sv $rtl_library_arguments "$testbench" \
    > "$test_build_directory/build.log" 2>&1; then
    echo "[FAIL]  $test_module build"
    cat "$test_build_directory/build.log"
    return 1
  fi
}

run_module_test() {
  test_module=$1
  test_build_directory="$build_directory/tests/$test_module/$build_mode"

  build_test "$test_module"
  echo "[RUN]   $test_module"
  if ! "$test_build_directory/obj/${test_module}_test" \
    > "$test_build_directory/test.log" 2>&1; then
    echo "[FAIL]  $test_module"
    cat "$test_build_directory/test.log"
    return 1
  fi
  report_module_pass "$test_module"
}

run_cpu_system_program() {
  program_name=$1
  program_source="sw/tests/cpu_system/$program_name.S"
  checks_file="sw/tests/cpu_system/$program_name.checks"
  program_build_directory="$build_directory/cpu_system/$program_name"
  expected_file="$program_build_directory/program.expected"

  if [ ! -f "$program_source" ] || [ ! -f "$checks_file" ]; then
    echo "Missing $program_source or $checks_file" >&2
    exit 1
  fi

  mkdir -p "$program_build_directory"

  echo "[RUN]   cpu_system/$program_name"
  if ! scripts/build_cpu_system_program.sh "$program_source" "$program_build_directory" \
    > "$program_build_directory/build.log" 2>&1; then
    echo "[FAIL]  cpu_system/$program_name build"
    cat "$program_build_directory/build.log"
    return 1
  fi

  echo "[SPIKE] cpu_system/$program_name"
  if ! python3 scripts/generate_cpu_system_expected.py \
    "$checks_file" "$program_build_directory/program.elf" "$expected_file" \
    > "$program_build_directory/spike.log" 2>&1; then
    echo "[FAIL]  cpu_system/$program_name Spike reference"
    cat "$program_build_directory/spike.log"
    return 1
  fi

  test_end_pc=$(riscv32-none-elf-nm "$program_build_directory/program.elf" \
    | awk '$3 == "_test_end" { print $1; exit }')
  if [ -z "$test_end_pc" ]; then
    echo "[FAIL]  cpu_system/$program_name: missing _test_end symbol" >&2
    return 1
  fi

  if ! "$build_directory/tests/cpu_system/$build_mode/obj/cpu_system_test" \
    "+memory_init=$program_build_directory/program.hex" \
    "+test_end_pc=$test_end_pc" \
    "+timeout_cycles=${CPU_TEST_TIMEOUT_CYCLES:-1000}" \
    "+expected_file=$expected_file" \
    "+trace_file=$program_build_directory/waveform.fst" \
    > "$program_build_directory/test.log" 2>&1; then
    echo "[FAIL]  cpu_system/$program_name"
    cat "$program_build_directory/test.log"
    return 1
  fi
  echo "[PASS]  cpu_system/$program_name"
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
  mkdir -p "$build_directory"
  TEST_TOTAL=$(find tb -type f -name '*_tb.sv' | wc -l)
  TEST_PROGRESS_FILE="$build_directory/.test-progress"
  printf '0\n' > "$TEST_PROGRESS_FILE"
  export TEST_TOTAL TEST_PROGRESS_FILE

  find tb -type f -name '*_tb.sv' -exec basename {} _tb.sv \; \
    | sort \
    | xargs -r -n1 -P "$test_jobs" scripts/run_tests.sh
elif [ "$module" = "cpu_system" ]; then
  run_cpu_system_tests "$program"
  if [ -n "${TEST_TOTAL:-}" ]; then
    report_module_pass cpu_system
  fi
elif [ -n "$program" ]; then
  echo "A program name is only valid with: just test cpu_system PROGRAM" >&2
  exit 1
else
  run_module_test "$module"
fi
