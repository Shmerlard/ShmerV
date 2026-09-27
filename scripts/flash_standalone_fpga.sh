#!/bin/sh
set -eu

design=${1:?usage: flash_standalone_fpga.sh DESIGN [sram|flash]}
mode=${2:-sram}
bitstream="build/fpga/standalone/$design/$design.fs"

if [ ! -f "$bitstream" ]; then
  echo "Missing $bitstream; run: just fpga-build $design" >&2
  exit 1
fi

case "$mode" in
  sram) openFPGALoader -b tangnano9k "$bitstream" ;;
  flash) openFPGALoader -b tangnano9k -f "$bitstream" ;;
  *) echo "Mode must be sram or flash" >&2; exit 1 ;;
esac
