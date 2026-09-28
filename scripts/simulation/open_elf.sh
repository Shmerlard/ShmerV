#!/bin/sh
set -eu

elf_file=${1:-}

if [ -z "$elf_file" ] || [ ! -f "$elf_file" ]; then
  echo "Missing ELF file: $elf_file" >&2
  exit 1
fi

viewer_command='riscv32-none-elf-objdump -d "$1" | less -R'

xdg-terminal-exec sh -c "$viewer_command" sh "$elf_file" >/dev/null 2>&1 &
