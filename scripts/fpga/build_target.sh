#!/bin/sh
set -eu

board=tang_nano_9k
target=${1:-}
program=${2:-}

if [ -z "$target" ]; then
  echo "Usage: just fpga-build TARGET [PROGRAM]" >&2
  echo "Available targets:" >&2
  scripts/fpga/list.sh targets >&2
  exit 1
fi

target_directory="fpga/$board/$target"
top="${target}_top"
sources_file="$target_directory/sources.f"
constraints_file="$target_directory/pins.cst"
build_directory="build/fpga/$board/$target"
images_directory="$build_directory/images"

if [ ! -f "$sources_file" ] || [ ! -f "$constraints_file" ]; then
  echo "Unknown or incomplete FPGA target: $target" >&2
  exit 1
fi

case "$target" in
  cpu_system)
    if [ -z "$program" ]; then
      echo "A program is required: just fpga-build cpu_system PROGRAM" >&2
      echo "Available programs:" >&2
      scripts/fpga/list.sh programs >&2
      exit 1
    fi

    program_directory="sw/programs/$program"
    if [ -f "$program_directory/main.c" ]; then
      program_source="$program_directory/main.c"
    elif [ -f "$program_directory/main.S" ]; then
      program_source="$program_directory/main.S"
    else
      echo "Missing main.c or main.S for program: $program" >&2
      exit 1
    fi

    scripts/software/build_program.sh \
      "$program_source" "$build_directory/software" sw/linker/tang_nano_9k_16k.ld
    image_name=$program
    ;;
  *)
    if [ -n "$program" ]; then
      echo "Target $target does not accept a software program" >&2
      exit 1
    fi
    image_name=$target
    ;;
esac

sources=$(tr '\n' ' ' < "$sources_file")
mkdir -p "$build_directory" "$images_directory"

yosys -Q -l "$build_directory/synthesis.log" -p "
  read_slang --top $top $sources
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

bitstream="$images_directory/$image_name.fs"
gowin_pack -d GW1N-9C -o "$bitstream" "$build_directory/routed.json"
echo "Bitstream: $bitstream"
