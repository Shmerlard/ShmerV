#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 PROGRAM_SOURCE OUTPUT_DIRECTORY" >&2
  exit 1
fi

program_source=$1
output_directory=$2

mkdir -p "$output_directory"

riscv32-none-elf-as -march=rv32i -mabi=ilp32 \
  -o "$output_directory/program.o" "$program_source"
riscv32-none-elf-objcopy -O binary --only-section=.text \
  "$output_directory/program.o" "$output_directory/program.bin"
od -An -v -w4 -tx4 "$output_directory/program.bin" > "$output_directory/program.hex"
