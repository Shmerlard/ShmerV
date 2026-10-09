#!/bin/sh
set -eu

build_directory=build/synthesis/gowin
log_file="$build_directory/synthesis.log"
netlist_file="$build_directory/cpu.json"
# core_types imports csr_types, so compile that package first.
package_sources="rtl/types/csr_types.sv $(find rtl/types -type f -name '*.sv' ! -path 'rtl/types/csr_types.sv' | sort)"

mkdir -p "$build_directory"

yosys -Q -l "$log_file" -p "
  read_slang --ignore-initial --top cpu $package_sources rtl/core/*.sv rtl/core/pipeline_registers/*.sv rtl/core/stages/*.sv
  synth_gowin -family gw1n -top cpu -noiopads -json $netlist_file
  stat
"

echo "Gowin synthesis report: $log_file"
echo "Gowin JSON netlist: $netlist_file"
