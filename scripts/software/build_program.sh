#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 PROGRAM_SOURCE OUTPUT_DIRECTORY [LINKER_SCRIPT]" >&2
  exit 1
fi

program_source=$1
output_directory=$2
linker_script=${3:-sw/linker/simulation_32k.ld}

mkdir -p "$output_directory"

case "$program_source" in
  *.S)
    riscv32-none-elf-as -march=rv32i -mabi=ilp32 \
      -o "$output_directory/program.o" "$program_source"
    riscv32-none-elf-ld -m elf32lriscv \
      -T "$linker_script" \
      -o "$output_directory/program.elf" "$output_directory/program.o"
    ;;

  *.c)
    riscv32-none-elf-gcc -march=rv32i -mabi=ilp32 -O0 \
      -ffreestanding -fno-pic -fno-stack-protector \
      -fno-unwind-tables -fno-asynchronous-unwind-tables \
      -msmall-data-limit=0 -Isw/include -c \
      -o "$output_directory/program.o" "$program_source"
    riscv32-none-elf-as -march=rv32i -mabi=ilp32 \
      -o "$output_directory/start.o" sw/runtime/start.S
    riscv32-none-elf-ld -m elf32lriscv \
      -T "$linker_script" \
      -o "$output_directory/program.elf" \
      "$output_directory/start.o" "$output_directory/program.o"
    ;;

  *)
    echo "Unsupported CPU-system source: $program_source" >&2
    exit 1
    ;;
esac

riscv32-none-elf-objcopy -O binary \
  "$output_directory/program.elf" "$output_directory/program.bin"
od -An -v -w4 -tx4 "$output_directory/program.bin" > "$output_directory/program.hex"

awk '{ print substr($1, 7, 2) }' "$output_directory/program.hex" > "$output_directory/program_lane0.hex"
awk '{ print substr($1, 5, 2) }' "$output_directory/program.hex" > "$output_directory/program_lane1.hex"
awk '{ print substr($1, 3, 2) }' "$output_directory/program.hex" > "$output_directory/program_lane2.hex"
awk '{ print substr($1, 1, 2) }' "$output_directory/program.hex" > "$output_directory/program_lane3.hex"
