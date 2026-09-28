#!/bin/sh
set -eu

kind=${1:-all}

list_targets() {
  for sources_file in fpga/tang_nano_9k/*/sources.f; do
    if [ -f "$sources_file" ]; then
      basename "$(dirname "$sources_file")"
    fi
  done
}

list_programs() {
  for program_directory in sw/programs/*; do
    if [ -f "$program_directory/main.c" ] || [ -f "$program_directory/main.S" ]; then
      basename "$program_directory"
    fi
  done
}

list_images() {
  find build/fpga/tang_nano_9k -type f -path '*/images/*.fs' -print 2>/dev/null | sort
}

case "$kind" in
  targets) list_targets ;;
  programs) list_programs ;;
  images) list_images ;;
  all)
    echo "Targets:"
    list_targets
    echo
    echo "Programs:"
    list_programs
    echo
    echo "Built images:"
    list_images
    ;;
  *) echo "Usage: just fpga-list [targets|programs|images|all]" >&2; exit 1 ;;
esac
