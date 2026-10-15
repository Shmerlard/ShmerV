#!/bin/sh
set -eu

target=${1:-}

if [ -z "$target" ]; then
  echo "Built FPGA images:"
  scripts/fpga/list.sh images
  exit 0
fi

. scripts/fpga/image_selection.sh
select_flash_image "$@"

if [ ! -f "$bitstream" ]; then
  echo "Missing FPGA image: $bitstream" >&2
  echo "Rebuild/repack for the selected backend; legacy images are not selected automatically." >&2
  exit 1
fi

case "$mode" in
  sram) openFPGALoader -b tangnano9k "$bitstream" ;;
  flash) openFPGALoader -b tangnano9k -f "$bitstream" ;;
  *) echo "Mode must be sram or flash" >&2; exit 1 ;;
esac
