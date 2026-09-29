#!/bin/sh
set -eu

board=tang_nano_9k
target=${1:-}
program=${2:-}

if [ "$target" != "cpu_system" ] || [ -z "$program" ]; then
  echo "Usage: just fpga-repack cpu_system PROGRAM" >&2
  exit 1
fi

target_directory="fpga/$board/$target"
sources_file="$target_directory/sources.f"
build_directory="build/fpga/$board/$target"
images_directory="$build_directory/images"
routed_netlist="$build_directory/routed.json"
saved_fingerprint_file="$build_directory/hardware.sha256"
program_directory="sw/programs/$program"

if [ -f "$program_directory/main.c" ]; then
  program_source="$program_directory/main.c"
elif [ -f "$program_directory/main.S" ]; then
  program_source="$program_directory/main.S"
else
  echo "Missing main.c or main.S for program: $program" >&2
  exit 1
fi

if [ ! -f "$routed_netlist" ]; then
  echo "Missing routed design; run: just fpga-build cpu_system $program" >&2
  exit 1
fi
if [ ! -f "$saved_fingerprint_file" ]; then
  echo "Missing hardware fingerprint; run one full fpga-build first" >&2
  exit 1
fi

saved_fingerprint=$(cat "$saved_fingerprint_file")
current_fingerprint=$(scripts/fpga/hardware_fingerprint.sh "$target")
if [ "$saved_fingerprint" != "$current_fingerprint" ]; then
  echo "FPGA hardware sources changed; a full fpga-build is required" >&2
  exit 1
fi

mkdir -p "$build_directory/software" "$images_directory"
scripts/software/build_program.sh \
  "$program_source" "$build_directory/software" sw/linker/tang_nano_9k_16k.ld

sources=$(tr '\n' ' ' < "$sources_file")
fresh_netlist="$build_directory/program-netlist.json"
repacked_netlist="$build_directory/repacked-routed.json"

yosys -Q -q -l "$build_directory/repack-synthesis.log" -p "
  read_verilog -lib +/gowin/cells_sim.v
  read_slang --top cpu_system_top $sources
  synth_gowin -family gw1n -top cpu_system_top -json $fresh_netlist
"

python3 scripts/fpga/patch_bram_init.py \
  "$fresh_netlist" "$routed_netlist" "$repacked_netlist"

bitstream="$images_directory/$program.fs"
gowin_pack -d GW1N-9C -o "$bitstream" "$repacked_netlist"
echo "Repacked bitstream: $bitstream"
