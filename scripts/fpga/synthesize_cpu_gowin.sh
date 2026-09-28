#!/bin/sh
set -eu

build_directory=build/synthesis/gowin
log_file="$build_directory/synthesis.log"
netlist_file="$build_directory/cpu.json"

mkdir -p "$build_directory"

yosys -Q -l "$log_file" -p "
  read_slang --ignore-initial --top cpu rtl/types/csr_types.sv rtl/types/core_types.sv rtl/core/*.sv rtl/core/pipeline_registers/*.sv rtl/core/stages/*.sv
  synth_gowin -family gw1n -top cpu -noiopads -json $netlist_file
  stat
"

echo "Gowin synthesis report: $log_file"
echo "Gowin JSON netlist: $netlist_file"
