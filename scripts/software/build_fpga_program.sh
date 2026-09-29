#!/bin/sh
set -eu

program=$1
program_directory="sw/programs/$program"

if [ -f "$program_directory/main.c" ]; then
  program_source="$program_directory/main.c"
elif [ -f "$program_directory/main.S" ]; then
  program_source="$program_directory/main.S"
else
  echo "Unknown program or missing main.c/main.S: $program" >&2
  exit 1
fi

scripts/software/build_program.sh \
  "$program_source" \
  build/fpga/tang_nano_9k/cpu_system/software \
  sw/linker/tang_nano_9k_16k.ld

echo "Firmware: build/fpga/tang_nano_9k/cpu_system/software/program.hex"
