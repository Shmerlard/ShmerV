#!/bin/sh
set -eu

module=${1:-}
program=${2:-}
display=${3:-}

case "$display" in
  ""|--elf) ;;
  *)
    echo "Unknown display option: $display" >&2
    echo "Usage: just sim MODULE [PROGRAM] [--elf]" >&2
    exit 1
    ;;
esac

if [ -z "$module" ]; then
  echo "Usage: just sim MODULE [PROGRAM]" >&2
  exit 1
fi

if [ "$module" = "soc" ]; then
  if [ -z "$program" ]; then
    echo "Usage: just sim soc PROGRAM"
    echo "Available programs:"
    for program_directory in tb/core/programs/*; do
      if [ -d "$program_directory" ]; then
        program_name=$(basename "$program_directory")
        if [ -f "$program_directory/$program_name.S" ] \
          || [ -f "$program_directory/$program_name.c" ]; then
          echo "$program_name"
        fi
      fi
    done
    exit 0
  fi
  waveform="build/soc/$program/waveform.fst"
  elf_file="build/soc/$program/program.elf"
elif [ -n "$program" ]; then
  echo "A program name is only valid for soc" >&2
  exit 1
else
  waveform="build/tests/$module/waveform.fst"
fi

if [ "$display" = "--elf" ] && [ "$module" != "soc" ]; then
  echo "--elf is only valid for soc simulations" >&2
  exit 1
fi

# Do not open a stale waveform if the traced build or run fails early.
rm -f "$waveform"

test_status=0
scripts/test/run_tests.sh "$module" "$program" trace || test_status=$?

if [ ! -f "$waveform" ]; then
  echo "No waveform was generated: $waveform" >&2
  if [ "$test_status" -eq 0 ]; then
    exit 1
  fi
  exit "$test_status"
fi

if [ "$display" = "--elf" ]; then
  scripts/simulation/open_elf.sh "$elf_file"
fi

viewer_status=0
scripts/simulation/open_wave.sh "$module" "$program" || viewer_status=$?

if [ "$test_status" -ne 0 ]; then
  exit "$test_status"
fi
exit "$viewer_status"
