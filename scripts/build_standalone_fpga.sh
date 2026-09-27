#!/bin/sh
set -eu

design=${1:?usage: build_standalone_fpga.sh DESIGN}
design_directory="fpga/standalone/$design"
top="${design}_fpga_top"
sources_file="$design_directory/sources.txt"
constraints_file="$design_directory/tang_nano_9k.cst"
build_directory="build/fpga/standalone/$design"

if [ ! -f "$sources_file" ] || [ ! -f "$constraints_file" ]; then
  echo "Missing standalone FPGA files for $design" >&2
  exit 1
fi

sources=$(tr '\n' ' ' < "$sources_file")
mkdir -p "$build_directory"

yosys -Q -l "$build_directory/synthesis.log" -p "
  read_slang --ignore-initial --top $top $sources
  synth_gowin -family gw1n -top $top -json $build_directory/netlist.json
"

nextpnr-himbaechel \
  --device GW1NR-LV9QN88PC6/I5 \
  --vopt family=GW1N-9C \
  --vopt cst="$constraints_file" \
  --json "$build_directory/netlist.json" \
  --write "$build_directory/routed.json" \
  --freq 27 \
  --report "$build_directory/report.json" \
  --log "$build_directory/nextpnr.log"

gowin_pack -d GW1N-9C -o "$build_directory/$design.fs" "$build_directory/routed.json"
echo "Bitstream: $build_directory/$design.fs"
