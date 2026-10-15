#!/bin/sh
# Pure argument/path selection: no hardware or filesystem operations.
select_flash_image() {
  target=${1:-}
  selection=${2:-}
  backend=nextpnr
  mode=sram
  mode_seen=
  backend_seen=
  if [ "$#" -ge 2 ]; then shift 2; else return 1; fi
  if [ "$target" != soc ]; then
    set -- "$selection" "$@"
    selection=$target
  fi
  for option in "$@"; do
    case "$option" in
      "") ;;
      --gowin)
        if [ -n "$backend_seen" ]; then echo "Duplicate backend option" >&2; return 1; fi
        backend=gowin
        backend_seen=1
        ;;
      sram|flash)
        if [ -n "$mode_seen" ]; then echo "Specify sram or flash only once" >&2; return 1; fi
        mode=$option
        mode_seen=1
        ;;
      *) echo "Unknown flash option: $option" >&2; return 1 ;;
    esac
  done
  case "$selection" in
    ""|--*)
      echo "Usage: just fpga-flash soc PROGRAM|ide [--gowin] [sram|flash]" >&2
      echo "For the original IDE image use: just fpga-flash soc ide --gowin" >&2
      return 1 ;;
  esac
  if [ "$backend" = gowin ] && [ "$target" != soc ]; then
    echo "Gowin image selection is supported only for soc" >&2
    return 1
  fi
  if [ "$target" = soc ] && [ "$selection" = ide ]; then
    if [ "$backend" != gowin ]; then echo "The ide image requires --gowin" >&2; return 1; fi
    bitstream=impl/pnr/ShmerV.fs
  else
    bitstream="build/fpga/tang_nano_9k/$target/images/$backend/$selection.fs"
  fi
}
