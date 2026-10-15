#!/bin/sh
set -eu

board=tang_nano_9k
target=${1:-}
selection=${2:-}
requested_mode=${3:-}
bitstream=

if [ -z "$target" ]; then
  echo "Built FPGA images:"
  scripts/fpga/list.sh images
  exit 0
fi

case "$target" in
  soc)
    if [ -z "$selection" ]; then
      echo "Usage: just fpga-flash soc PROGRAM|--gowin [sram|flash]" >&2
      exit 1
    fi
    image_name=$selection
    if [ "$selection" = --gowin ]; then
      bitstream="impl/pnr/ShmerV.fs"
    fi
    mode=${requested_mode:-sram}
    ;;
  *)
    image_name=$target
    if [ -n "$requested_mode" ]; then
      echo "Unexpected extra argument: $requested_mode" >&2
      exit 1
    fi
    case "$selection" in
      "") mode=sram ;;
      sram|flash) mode=$selection ;;
      *) echo "Mode must be sram or flash" >&2; exit 1 ;;
    esac
    ;;
esac

if [ -z "$bitstream" ]; then
  bitstream="build/fpga/$board/$target/images/$image_name.fs"
fi

if [ ! -f "$bitstream" ]; then
  echo "Missing FPGA image: $bitstream" >&2
  exit 1
fi

case "$mode" in
  sram) openFPGALoader -b tangnano9k "$bitstream" ;;
  flash) openFPGALoader -b tangnano9k -f "$bitstream" ;;
  *) echo "Mode must be sram or flash" >&2; exit 1 ;;
esac
