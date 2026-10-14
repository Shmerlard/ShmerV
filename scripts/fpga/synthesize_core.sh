#!/bin/sh
set -eu

build_directory=build/synthesis/core
log_file="$build_directory/synthesis.log"
# core_types imports csr_types, so compile that package first.
package_sources="rtl/types/csr_types.sv $(find rtl/types -type f -name '*.sv' ! -path 'rtl/types/csr_types.sv' | sort)"

mkdir -p "$build_directory"

yosys -Q -l "$log_file" -p "
  read_slang --ignore-initial --top core $package_sources rtl/core/*.sv rtl/core/pipeline_registers/*.sv rtl/core/stages/*.sv
  synth -top core
  stat
"

echo "Synthesis report: $log_file"
