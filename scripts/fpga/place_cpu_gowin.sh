#!/bin/sh
set -eu

build_directory=build/place/gowin
synthesis_log="$build_directory/synthesis.log"
nextpnr_log="$build_directory/nextpnr.log"
netlist_file="$build_directory/cpu-synthesis-top.json"
routed_file="$build_directory/cpu-synthesis-top-routed.json"
report_file="$build_directory/report.json"

mkdir -p "$build_directory"

yosys -Q -l "$synthesis_log" -p "
  read_slang --ignore-initial --top cpu_synthesis_top rtl/types/csr_types.sv rtl/types/core_types.sv rtl/core/*.sv rtl/core/pipeline_registers/*.sv rtl/core/stages/*.sv fpga/tang_nano_9k/cpu_synthesis/top.sv
  synth_gowin -family gw1n -top cpu_synthesis_top -json $netlist_file
"

nextpnr-himbaechel \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --vopt cst=fpga/tang_nano_9k/cpu_synthesis/pins.cst \
  --json "$netlist_file" \
  --write "$routed_file" \
  --freq 27 \
  --report "$report_file" \
  --log "$nextpnr_log"

echo "Place-and-route report: $report_file"
echo "Place-and-route log: $nextpnr_log"
