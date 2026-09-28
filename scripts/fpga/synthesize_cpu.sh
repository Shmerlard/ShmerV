#!/bin/sh
set -eu

build_directory=build/synthesis/cpu
log_file="$build_directory/synthesis.log"

mkdir -p "$build_directory"

yosys -Q -l "$log_file" -p '
  read_slang --ignore-initial --top cpu rtl/types/csr_types.sv rtl/types/core_types.sv rtl/core/*.sv rtl/core/pipeline_registers/*.sv rtl/core/stages/*.sv
  synth -top cpu
  stat
'

echo "Synthesis report: $log_file"
